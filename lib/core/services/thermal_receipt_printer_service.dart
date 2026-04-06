import 'dart:async';
import 'dart:io' show Platform;

import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';
import 'package:intl/intl.dart';

class PrinterDevice {
  final String name;
  final String macAddress;
  final bool isPaired;

  const PrinterDevice({
    required this.name,
    required this.macAddress,
    this.isPaired = true,
  });
}

class ShiftSoldProductSummary {
  final String name;
  final int quantity;

  const ShiftSoldProductSummary({required this.name, required this.quantity});
}

abstract interface class ThermalReceiptPrinterService {
  Future<PrinterDevice?> selectDevice({required BuildContext context});
  Future<List<PrinterDevice>> getPairedDevices();
  Future<List<PrinterDevice>> discoverNearbyDevices({
    Duration timeout = const Duration(seconds: 8),
  });
  Future<bool> pairDevice({required String macAddress});
  Future<bool> get isConnected;
  Future<void> connect({required String macAddress});
  Future<void> printTestReceipt({
    required BuildContext context,
    required StoreSettings storeSettings,
    required String cashierName,
  });
  Future<void> printOrderReceipt({
    required BuildContext context,
    required OrderEntity order,
    required StoreSettings storeSettings,
    required String cashierName,
  });

  Future<void> printShiftCloseReport({
    required BuildContext context,
    required StoreSettings storeSettings,
    required String cashierName,
    required DateTime openedAt,
    required DateTime closedAt,
    required int openingBalance,
    required int closingBalance,
    required int totalCashSales,
    required int totalQrisSales,
    required int totalCashIn,
    required int totalCashOut,
    required int totalTransactions,
    required List<ShiftSoldProductSummary> soldProducts,
  });
}

class ThermalReceiptPrinterServiceImpl implements ThermalReceiptPrinterService {
  String? _connectedAddress;

  @override
  Future<PrinterDevice?> selectDevice({required BuildContext context}) async {
    _ensureAndroidOnly();
    final selected = await FlutterBluetoothPrinter.selectDevice(context);
    if (selected == null) {
      return null;
    }

    return PrinterDevice(
      name: (selected.name ?? '').trim(),
      macAddress: selected.address.trim(),
      isPaired: true,
    );
  }

  @override
  Future<List<PrinterDevice>> getPairedDevices() {
    return discoverNearbyDevices();
  }

  @override
  Future<List<PrinterDevice>> discoverNearbyDevices({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    _ensureAndroidOnly();
    await _ensureBluetoothReady();

    final discovered = <String, PrinterDevice>{};
    final completer = Completer<List<PrinterDevice>>();

    final subscription = FlutterBluetoothPrinter.discovery.listen((state) {
      if (state is DiscoveryResult) {
        for (final device in state.devices) {
          final address = device.address.trim();
          if (address.isEmpty) {
            continue;
          }

          discovered[address] = PrinterDevice(
            name: (device.name ?? '').trim(),
            macAddress: address,
            isPaired: true,
          );
        }
      } else if (state is BluetoothDevice) {
        final address = state.address.trim();
        if (address.isNotEmpty) {
          discovered[address] = PrinterDevice(
            name: (state.name ?? '').trim(),
            macAddress: address,
            isPaired: true,
          );
        }
      }
    });

    Future<void>.delayed(timeout).then((_) {
      if (!completer.isCompleted) {
        completer.complete(discovered.values.toList(growable: false));
      }
    });

    final devices = await completer.future;
    await subscription.cancel();
    return devices;
  }

  @override
  Future<bool> pairDevice({required String macAddress}) async {
    return false;
  }

  @override
  Future<bool> get isConnected async {
    return _connectedAddress != null;
  }

  @override
  Future<void> connect({required String macAddress}) async {
    _ensureAndroidOnly();
    await _ensureBluetoothReady();

    final connected = await FlutterBluetoothPrinter.connect(macAddress);
    if (!connected) {
      throw Exception('Failed to connect printer.');
    }

    _connectedAddress = macAddress;
  }

  @override
  Future<void> printTestReceipt({
    required BuildContext context,
    required StoreSettings storeSettings,
    required String cashierName,
  }) async {
    await _printWithReceipt(
      context: context,
      builder: (_) => _ReceiptLayout(
        sections: [
          _center(storeSettings.storeName, bold: true, fontSize: 22),
          _center(storeSettings.storeAddress),
          _divider(),
          _center('TEST PRINT', bold: true),
          _center('Jika teks ini tercetak, printer siap dipakai.'),
          _spacer(),
          _line('Kasir: $cashierName'),
          _line(
            'Waktu: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
          ),
          _divider(),
          _center('FLOW POS', bold: true),
        ],
      ),
    );
  }

  @override
  Future<void> printOrderReceipt({
    required BuildContext context,
    required OrderEntity order,
    required StoreSettings storeSettings,
    required String cashierName,
  }) async {
    final subtotal = order.items.fold<int>(
      0,
      (sum, item) => sum + (item.quantity * item.unitPrice),
    );
    final taxAmount = ((subtotal * storeSettings.taxPercentage) / 100).round();
    final serviceAmount =
        ((subtotal * storeSettings.serviceChargePercentage) / 100).round();

    final itemWidgets = <Widget>[];
    for (final item in order.items) {
      itemWidgets.addAll(_buildItemSection(item));
    }

    await _printWithReceipt(
      context: context,
      builder: (_) => _ReceiptLayout(
        sections: [
          _center(storeSettings.storeName, bold: true, fontSize: 22),
          _center(storeSettings.storeAddress),
          _divider(),
          _kv(
            DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
            cashierName,
          ),
          _line('Table: T${order.tableNumber}'),
          _divider(),
          ...itemWidgets,
          _divider(),
          _kv('Sub Total', formatRupiah(subtotal), valueBold: true),
          _kv(
            'Tax (${_formatPercentage(storeSettings.taxPercentage)})',
            formatRupiah(taxAmount),
          ),
          if (serviceAmount > 0)
            _kv(
              'Service (${_formatPercentage(storeSettings.serviceChargePercentage)})',
              formatRupiah(serviceAmount),
            ),
          _kv(
            'Bayar (${order.payment.method.toUpperCase()})',
            formatRupiah(order.payment.amountPaid),
          ),
          _kv(
            'Kembali',
            formatRupiah(order.payment.changeGiven),
            valueBold: true,
          ),
        ],
      ),
    );
  }

  @override
  Future<void> printShiftCloseReport({
    required BuildContext context,
    required StoreSettings storeSettings,
    required String cashierName,
    required DateTime openedAt,
    required DateTime closedAt,
    required int openingBalance,
    required int closingBalance,
    required int totalCashSales,
    required int totalQrisSales,
    required int totalCashIn,
    required int totalCashOut,
    required int totalTransactions,
    required List<ShiftSoldProductSummary> soldProducts,
  }) async {
    final totalPenerimaan = totalCashSales + totalQrisSales + totalCashIn;
    final saldoAkhir = totalPenerimaan + openingBalance - closingBalance;
    final totalProdukTerjual = soldProducts.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    final soldWidgets = soldProducts.isEmpty
        ? <Widget>[_line('Tidak ada data penjualan menu')]
        : soldProducts
              .map((item) => _kv(item.name, '[${item.quantity}]'))
              .toList(growable: false);

    await _printWithReceipt(
      context: context,
      builder: (_) => _ReceiptLayout(
        sections: [
          _center(storeSettings.storeName, bold: true),
          _center(storeSettings.storeAddress),
          _divider('='),
          _center('LAPORAN TUTUP KASIR', bold: true),
          _center('TRANSAKSI PENJUALAN', bold: true),
          _spacer(),
          _line('Kasir: $cashierName'),
          _line('Waktu Buka: ${_formatShiftDateTime(openedAt)}'),
          _line('Waktu Tutup: ${_formatShiftDateTime(closedAt)}'),
          _spacer(),
          _kv('Modal Awal', formatRupiah(openingBalance)),
          _kv('CASH', formatRupiah(totalCashSales)),
          _kv('QRIS', formatRupiah(totalQrisSales)),
          if (totalCashIn > 0) _kv('Kas Masuk', formatRupiah(totalCashIn)),
          if (totalCashOut > 0) _kv('Kas Keluar', formatRupiah(totalCashOut)),
          _kv(
            'Total Penerimaan',
            formatRupiah(totalPenerimaan),
            valueBold: true,
          ),
          _divider(),
          _kv('Saldo Akhir', formatRupiah(saldoAkhir), valueBold: true),
          _divider(),
          _kv('Transaksi masuk', '$totalTransactions'),
          _divider('='),
          const SizedBox(height: 28),
          _center('LAPORAN TUTUP KASIR', bold: true),
          _center('PENJUALAN MENU', bold: true),
          _spacer(),
          _line('Kasir: $cashierName'),
          _line('Waktu Buka: ${_formatShiftDateTime(openedAt)}'),
          _line('Waktu Tutup: ${_formatShiftDateTime(closedAt)}'),
          _spacer(),
          _line('Produk Terjual'),
          _divider(),
          ...soldWidgets,
          _divider(),
          _kv('Total', '[$totalProdukTerjual]', valueBold: true),
        ],
      ),
    );
  }

  Future<void> _printWithReceipt({
    required BuildContext context,
    required WidgetBuilder builder,
  }) async {
    final address = _connectedAddress;
    if (address == null) {
      throw Exception('Printer is not connected.');
    }

    final overlay = Overlay.of(context, rootOverlay: true);

    final controllerCompleter = Completer<ReceiptController>();

    final entry = OverlayEntry(
      builder: (_) => IgnorePointer(
        ignoring: true,
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned(
                left: -5000,
                top: 0,
                child: SizedBox(
                  width: 420,
                  child: Receipt(
                    builder: builder,
                    backgroundColor: Colors.white,
                    onInitialized: (controller) {
                      controller.paperSize = PaperSize.mm58;
                      if (!controllerCompleter.isCompleted) {
                        controllerCompleter.complete(controller);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    overlay.insert(entry);

    try {
      final controller = await controllerCompleter.future;
      await Future<void>.delayed(const Duration(milliseconds: 120));
      final printed = await controller.print(
        address: address,
        keepConnected: true,
        cutPaper: true,
        addFeeds: 2,
      );

      if (!printed) {
        throw Exception('Failed to send data to printer.');
      }
    } finally {
      entry.remove();
    }
  }

  Future<void> _ensureBluetoothReady() async {
    final state = await FlutterBluetoothPrinter.getState();
    if (state is! BluetoothEnabledState) {
      throw Exception('Bluetooth is turned off. Please enable it first.');
    }
  }

  void _ensureAndroidOnly() {
    if (!Platform.isAndroid) {
      throw Exception(
        'In-app Bluetooth scan/pair is currently supported on Android only.',
      );
    }
  }

  List<Widget> _buildItemSection(OrderItem item) {
    final subtotal = item.quantity * item.unitPrice;
    final compactPrice = _toCompactRupiah(item.unitPrice);

    return [
      _line(item.menuName, bold: true),
      if ((item.modifierSnapshot ?? '').trim().isNotEmpty)
        _line('Modifier: ${item.modifierSnapshot!.trim()}'),
      if ((item.notes ?? '').trim().isNotEmpty)
        _line('Notes: ${item.notes!.trim()}'),
      _kv('${item.quantity}x$compactPrice', formatRupiah(subtotal)),
    ];
  }

  Widget _divider([String char = '-']) {
    final unit = char == '='
        ? '============================'
        : '----------------------------';
    return _line(unit);
  }

  Widget _spacer() => const SizedBox(height: 8);

  Widget _center(String text, {bool bold = false, double fontSize = 20}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.black,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          height: 1.05,
        ),
      ),
    );
  }

  Widget _line(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          height: 1.05,
        ),
      ),
    );
  }

  Widget _kv(String left, String right, {bool valueBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 7,
            child: Text(
              left,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                height: 1.05,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              right,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: valueBold ? FontWeight.w700 : FontWeight.w400,
                height: 1.05,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _toCompactRupiah(int value) {
    return formatRupiah(value).replaceFirst('Rp ', '');
  }

  String _formatShiftDateTime(DateTime value) {
    return DateFormat('dd MMM yyyy, HH:mm').format(value.toLocal());
  }

  String _formatPercentage(double percentage) {
    if (percentage == percentage.toInt()) {
      return '${percentage.toInt()}%';
    }

    final normalized = percentage.toStringAsFixed(2);
    return '${normalized.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\\.$'), '')}%';
  }
}

class _ReceiptLayout extends StatelessWidget {
  final List<Widget> sections;

  const _ReceiptLayout({required this.sections});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [...sections, const SizedBox(height: 12)],
    );
  }
}
