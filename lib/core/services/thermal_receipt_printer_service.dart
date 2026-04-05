import 'dart:async';
import 'dart:io' show Platform;

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

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
  Future<List<PrinterDevice>> getPairedDevices();
  Future<List<PrinterDevice>> discoverNearbyDevices({
    Duration timeout = const Duration(seconds: 8),
  });
  Future<bool> pairDevice({required String macAddress});
  Future<bool> get isConnected;
  Future<void> connect({required String macAddress});
  Future<void> printTestReceipt({
    required StoreSettings storeSettings,
    required String cashierName,
  });
  Future<void> printOrderReceipt({
    required OrderEntity order,
    required StoreSettings storeSettings,
    required String cashierName,
  });

  Future<void> printShiftCloseReport({
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
  final FlutterBluetoothSerial _bluetoothSerial =
      FlutterBluetoothSerial.instance;

  @override
  Future<List<PrinterDevice>> getPairedDevices() async {
    _ensureAndroidOnly();
    await _ensureBluetoothReady();

    final devices = await _bluetoothSerial.getBondedDevices();
    return devices
        .map(
          (device) => PrinterDevice(
            name: (device.name ?? '').trim(),
            macAddress: device.address,
            isPaired: true,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<List<PrinterDevice>> discoverNearbyDevices({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    _ensureAndroidOnly();
    await _ensureBluetoothReady();

    final bondedDevices = await getPairedDevices();
    final byAddress = <String, PrinterDevice>{
      for (final device in bondedDevices) device.macAddress: device,
    };

    final stream = _bluetoothSerial.startDiscovery();
    final completer = Completer<void>();

    late final StreamSubscription<BluetoothDiscoveryResult> subscription;
    subscription = stream.listen(
      (result) {
        final name = (result.device.name ?? '').trim();
        byAddress[result.device.address] = PrinterDevice(
          name: name,
          macAddress: result.device.address,
          isPaired: byAddress[result.device.address]?.isPaired ?? false,
        );
      },
      onError: (_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      cancelOnError: false,
    );

    Timer? timeoutTimer;
    timeoutTimer = Timer(timeout, () {
      if (!completer.isCompleted) {
        completer.complete();
      }
    });

    await completer.future;
    timeoutTimer.cancel();
    await subscription.cancel();

    final devices = byAddress.values.toList(growable: false)
      ..sort((a, b) {
        if (a.isPaired != b.isPaired) {
          return a.isPaired ? -1 : 1;
        }

        final aName = a.name.isEmpty ? a.macAddress : a.name;
        final bName = b.name.isEmpty ? b.macAddress : b.name;
        return aName.toLowerCase().compareTo(bName.toLowerCase());
      });

    return devices;
  }

  @override
  Future<bool> pairDevice({required String macAddress}) async {
    _ensureAndroidOnly();
    await _ensureBluetoothReady();

    final paired = await _bluetoothSerial.bondDeviceAtAddress(macAddress);
    return paired ?? false;
  }

  @override
  Future<bool> get isConnected => PrintBluetoothThermal.connectionStatus;

  @override
  Future<void> connect({required String macAddress}) async {
    _ensureAndroidOnly();
    await _ensureBluetoothReady();
    final connected = await PrintBluetoothThermal.connect(
      macPrinterAddress: macAddress,
    );

    if (!connected) {
      throw Exception('Failed to connect printer.');
    }
  }

  @override
  Future<void> printTestReceipt({
    required StoreSettings storeSettings,
    required String cashierName,
  }) async {
    final connected = await isConnected;

    if (!connected) {
      throw Exception('Printer is not connected.');
    }

    final bytes = await _buildTestReceiptBytes(
      storeSettings: storeSettings,
      cashierName: cashierName,
    );

    final printed = await PrintBluetoothThermal.writeBytes(bytes);
    if (!printed) {
      throw Exception('Failed to send print data.');
    }
  }

  @override
  Future<void> printOrderReceipt({
    required OrderEntity order,
    required StoreSettings storeSettings,
    required String cashierName,
  }) async {
    final connected = await isConnected;

    if (!connected) {
      throw Exception('Printer is not connected.');
    }

    final bytes = await _buildReceiptBytes(
      order: order,
      storeSettings: storeSettings,
      cashierName: cashierName,
    );

    final printed = await PrintBluetoothThermal.writeBytes(bytes);

    if (!printed) {
      throw Exception('Failed to send print data.');
    }
  }

  @override
  Future<void> printShiftCloseReport({
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
    final connected = await isConnected;

    if (!connected) {
      throw Exception('Printer is not connected.');
    }

    final bytes = await _buildShiftCloseReportBytes(
      storeSettings: storeSettings,
      cashierName: cashierName,
      openedAt: openedAt,
      closedAt: closedAt,
      openingBalance: openingBalance,
      closingBalance: closingBalance,
      totalCashSales: totalCashSales,
      totalQrisSales: totalQrisSales,
      totalCashIn: totalCashIn,
      totalCashOut: totalCashOut,
      totalTransactions: totalTransactions,
      soldProducts: soldProducts,
    );

    final printed = await PrintBluetoothThermal.writeBytes(bytes);
    if (!printed) {
      throw Exception('Failed to send print data.');
    }
  }

  Future<void> _ensureBluetoothReady() async {
    final hasPermission =
        await PrintBluetoothThermal.isPermissionBluetoothGranted;

    if (!hasPermission) {
      throw Exception('Bluetooth permission is not granted.');
    }

    final enabled = await PrintBluetoothThermal.bluetoothEnabled;

    if (!enabled) {
      throw Exception('Bluetooth is turned off. Please enable it first.');
    }

    final serialEnabled = await _bluetoothSerial.isEnabled ?? false;
    if (!serialEnabled) {
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

  Future<List<int>> _buildReceiptBytes({
    required OrderEntity order,
    required StoreSettings storeSettings,
    required String cashierName,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];

    final subtotal = order.items.fold<int>(
      0,
      (sum, item) => sum + (item.quantity * item.unitPrice),
    );
    final taxAmount = ((subtotal * storeSettings.taxPercentage) / 100).round();
    final serviceAmount =
        ((subtotal * storeSettings.serviceChargePercentage) / 100).round();

    bytes.addAll(
      generator.text(
        storeSettings.storeName,
        styles: const PosStyles(
          align: PosAlign.center,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(
      generator.text(
        storeSettings.storeAddress,
        styles: const PosStyles(align: PosAlign.center),
      ),
    );

    bytes.addAll(generator.hr(ch: '-'));
    _appendTwoColumnRow(
      bytes,
      generator,
      left: DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt),
      right: cashierName,
    );
    bytes.addAll(generator.text('Table: T${order.tableNumber}'));
    bytes.addAll(generator.hr(ch: '-'));

    for (final item in order.items) {
      _appendItem(bytes, generator, item);
    }

    bytes.addAll(generator.hr(ch: '-'));
    _appendTwoColumnRow(
      bytes,
      generator,
      left: 'Sub Total',
      right: formatRupiah(subtotal),
      valueBold: true,
    );
    _appendTwoColumnRow(
      bytes,
      generator,
      left: 'Tax (${_formatPercentage(storeSettings.taxPercentage)})',
      right: formatRupiah(taxAmount),
    );

    if (serviceAmount > 0) {
      _appendTwoColumnRow(
        bytes,
        generator,
        left:
            'Service (${_formatPercentage(storeSettings.serviceChargePercentage)})',
        right: formatRupiah(serviceAmount),
      );
    }

    _appendTwoColumnRow(
      bytes,
      generator,
      left: 'Bayar (${order.payment.method.toUpperCase()})',
      right: formatRupiah(order.payment.amountPaid),
    );
    _appendTwoColumnRow(
      bytes,
      generator,
      left: 'Kembali',
      right: formatRupiah(order.payment.changeGiven),
      valueBold: true,
    );

    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    return bytes;
  }

  Future<List<int>> _buildShiftCloseReportBytes({
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
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];

    final totalPenerimaan = totalCashSales + totalQrisSales + totalCashIn;
    final saldoAkhir = totalPenerimaan + openingBalance - closingBalance;
    final totalProdukTerjual = soldProducts.fold<int>(
      0,
      (sum, item) => sum + item.quantity,
    );

    bytes.addAll(
      generator.text(
        storeSettings.storeName,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(
      generator.text(
        storeSettings.storeAddress,
        styles: const PosStyles(align: PosAlign.center),
      ),
    );

    bytes.addAll(generator.hr(ch: '='));
    bytes.addAll(
      generator.text(
        'LAPORAN TUTUP KASIR',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(
      generator.text(
        'TRANSAKSI PENJUALAN',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );

    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text('Kasir: $cashierName'));
    bytes.addAll(
      generator.text('Waktu Buka: ${_formatShiftDateTime(openedAt)}'),
    );
    bytes.addAll(
      generator.text('Waktu Tutup: ${_formatShiftDateTime(closedAt)}'),
    );
    bytes.addAll(generator.feed(1));

    _appendTwoColumnRow(
      bytes,
      generator,
      left: 'Modal Awal',
      right: formatRupiah(openingBalance),
    );
    _appendTwoColumnRow(
      bytes,
      generator,
      left: 'CASH',
      right: formatRupiah(totalCashSales),
    );
    _appendTwoColumnRow(
      bytes,
      generator,
      left: 'QRIS',
      right: formatRupiah(totalQrisSales),
    );

    if (totalCashIn > 0) {
      _appendTwoColumnRow(
        bytes,
        generator,
        left: 'Kas Masuk',
        right: formatRupiah(totalCashIn),
      );
    }

    if (totalCashOut > 0) {
      _appendTwoColumnRow(
        bytes,
        generator,
        left: 'Kas Keluar',
        right: formatRupiah(totalCashOut),
      );
    }

    _appendTwoColumnRow(
      bytes,
      generator,
      left: 'Total Penerimaan',
      right: formatRupiah(totalPenerimaan),
      valueBold: true,
    );

    bytes.addAll(generator.hr(ch: '-'));
    _appendTwoColumnRow(
      bytes,
      generator,
      left: 'Saldo Akhir',
      right: formatRupiah(saldoAkhir),
      valueBold: true,
    );
    bytes.addAll(generator.hr(ch: '-'));

    _appendTwoColumnRow(
      bytes,
      generator,
      left: 'Transaksi masuk',
      right: '$totalTransactions',
    );

    bytes.addAll(generator.hr(ch: '='));
    bytes.addAll(generator.feed(3));

    bytes.addAll(
      generator.text(
        'LAPORAN TUTUP KASIR',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(
      generator.text(
        'PENJUALAN MENU',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );

    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text('Kasir: $cashierName'));
    bytes.addAll(
      generator.text('Waktu Buka: ${_formatShiftDateTime(openedAt)}'),
    );
    bytes.addAll(
      generator.text('Waktu Tutup: ${_formatShiftDateTime(closedAt)}'),
    );
    bytes.addAll(generator.feed(1));

    bytes.addAll(generator.text('Produk Terjual'));
    bytes.addAll(generator.hr(ch: '-'));

    if (soldProducts.isEmpty) {
      bytes.addAll(generator.text('Tidak ada data penjualan menu'));
    } else {
      for (final item in soldProducts) {
        _appendTwoColumnRow(
          bytes,
          generator,
          left: item.name,
          right: '[${item.quantity}]',
        );
      }
    }

    bytes.addAll(generator.hr(ch: '-'));
    _appendTwoColumnRow(
      bytes,
      generator,
      left: 'Total',
      right: '[$totalProdukTerjual]',
      valueBold: true,
    );

    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    return bytes;
  }

  Future<List<int>> _buildTestReceiptBytes({
    required StoreSettings storeSettings,
    required String cashierName,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];

    final printedAt = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    bytes.addAll(
      generator.text(
        storeSettings.storeName,
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(
      generator.text(
        storeSettings.storeAddress,
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(
      generator.text(
        'TEST PRINT',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(
      generator.text(
        'Jika teks ini tercetak, printer siap dipakai.',
        styles: const PosStyles(align: PosAlign.center),
      ),
    );
    bytes.addAll(generator.feed(1));
    bytes.addAll(generator.text('Kasir: $cashierName'));
    bytes.addAll(generator.text('Waktu: $printedAt'));
    bytes.addAll(generator.hr(ch: '-'));
    bytes.addAll(
      generator.text(
        'FLOW POS',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      ),
    );
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    return bytes;
  }

  void _appendItem(List<int> bytes, Generator generator, OrderItem item) {
    final subtotal = item.quantity * item.unitPrice;
    final compactPrice = _toCompactRupiah(item.unitPrice);

    bytes.addAll(
      generator.text(item.menuName, styles: const PosStyles(bold: true)),
    );

    final modifier = item.modifierSnapshot?.trim();
    if (modifier != null && modifier.isNotEmpty) {
      bytes.addAll(generator.text('Modifier: $modifier'));
    }

    final notes = item.notes?.trim();
    if (notes != null && notes.isNotEmpty) {
      bytes.addAll(generator.text('Notes: $notes'));
    }

    _appendTwoColumnRow(
      bytes,
      generator,
      left: '${item.quantity}x$compactPrice',
      right: formatRupiah(subtotal),
    );
  }

  void _appendTwoColumnRow(
    List<int> bytes,
    Generator generator, {
    required String left,
    required String right,
    bool valueBold = false,
  }) {
    bytes.addAll(
      generator.row([
        PosColumn(
          width: 7,
          text: left,
          styles: const PosStyles(align: PosAlign.left),
        ),
        PosColumn(
          width: 5,
          text: right,
          styles: PosStyles(align: PosAlign.right, bold: valueBold),
        ),
      ]),
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
    return '${normalized.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')}%';
  }
}
