import 'dart:async';
import 'dart:io' show Platform;

import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

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
  Future<PrinterDevice?> selectDevice({required BuildContext context}) {
    _ensureAndroidOnly();
    return showModalBottomSheet<PrinterDevice>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return const _BluetoothDeviceSearchSheet();
      },
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
    await _ensureBluetoothPermissionsGranted();
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
    await _ensureBluetoothPermissionsGranted();
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
    if (state == BluetoothState.notPermitted) {
      throw Exception(
        'Bluetooth permission is not permitted. '
        'Please allow Nearby devices permission for this app.',
      );
    }

    if (state != BluetoothState.enabled) {
      throw Exception('Bluetooth is turned off. Please enable it first.');
    }
  }

  Future<void> _ensureBluetoothPermissionsGranted() async {
    if (!Platform.isAndroid) {
      return;
    }

    final statuses = await <Permission>[
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      Permission.location,
    ].request();

    final denied = statuses.values.any(
      (status) => status.isDenied || status.isRestricted,
    );
    if (denied) {
      throw Exception(
        'Bluetooth permission is not permitted. '
        'Please allow Nearby devices permission.',
      );
    }

    final permanentlyDenied = statuses.values.any(
      (status) => status.isPermanentlyDenied,
    );
    if (permanentlyDenied) {
      throw Exception(
        'Bluetooth permission is permanently denied. '
        'Open app settings and allow Nearby devices permission.',
      );
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

class _BluetoothDeviceSearchSheet extends StatefulWidget {
  const _BluetoothDeviceSearchSheet();

  @override
  State<_BluetoothDeviceSearchSheet> createState() =>
      _BluetoothDeviceSearchSheetState();
}

class _BluetoothDeviceSearchSheetState
    extends State<_BluetoothDeviceSearchSheet> {
  StreamSubscription<dynamic>? _discoverySubscription;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, PrinterDevice> _devicesByAddress =
      <String, PrinterDevice>{};

  bool _isLoading = true;
  String _query = '';
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _startDiscovery();
  }

  void _onSearchChanged() {
    setState(() {
      _query = _searchController.text.trim().toLowerCase();
    });
  }

  void _startDiscovery() {
    Future<void>(() async {
      final statuses = await <Permission>[
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.locationWhenInUse,
        Permission.location,
      ].request();

      if (!mounted) {
        return;
      }

      final permanentlyDenied = statuses.values.any(
        (status) => status.isPermanentlyDenied,
      );
      if (permanentlyDenied) {
        setState(() {
          _isLoading = false;
          _statusMessage =
              'Izin Bluetooth ditolak permanen. Buka Settings lalu izinkan Nearby devices.';
        });
        return;
      }

      final denied = statuses.values.any(
        (status) => status.isDenied || status.isRestricted,
      );
      if (denied) {
        setState(() {
          _isLoading = false;
          _statusMessage =
              'Bluetooth tidak diizinkan. Berikan izin Nearby devices untuk melanjutkan.';
        });
        return;
      }

      await Future<void>.delayed(const Duration(milliseconds: 500));

      // final state = await FlutterBluetoothPrinter.getState();
      if (!mounted) {
        return;
      }

      // if (state == BluetoothState.notPermitted) {
      //   setState(() {
      //     _isLoading = false;
      //     _statusMessage =
      //         'Bluetooth tidak diizinkan. Aktifkan Nearby devices di App Settings.';
      //   });
      //   return;
      // }

      // if (state != BluetoothState.enabled) {
      //   setState(() {
      //     _isLoading = false;
      //     _statusMessage =
      //         'Bluetooth sedang nonaktif. Silakan aktifkan Bluetooth.';
      //   });
      //   return;
      // }

      _discoverySubscription = FlutterBluetoothPrinter.discovery.listen((
        state,
      ) {
        if (!mounted) {
          return;
        }

        if (state is DiscoveryResult) {
          for (final device in state.devices) {
            final address = device.address.trim();
            if (address.isEmpty) {
              continue;
            }

            _devicesByAddress[address] = PrinterDevice(
              name: (device.name ?? '').trim(),
              macAddress: address,
              isPaired: true,
            );
          }

          setState(() {
            _isLoading = false;
            _statusMessage = null;
          });
          return;
        }

        if (state is BluetoothDevice) {
          final address = state.address.trim();
          if (address.isNotEmpty) {
            _devicesByAddress[address] = PrinterDevice(
              name: (state.name ?? '').trim(),
              macAddress: address,
              isPaired: true,
            );

            setState(() {
              _isLoading = false;
              _statusMessage = null;
            });
          }
          return;
        }

        // if (state is PermissionRestrictedState) {
        //   setState(() {
        //     _isLoading = false;
        //     _statusMessage =
        //         'Bluetooth tidak diizinkan. Aktifkan Nearby devices di App Settings.';
        //   });
        //   return;
        // }

        if (state is BluetoothDisabledState) {
          setState(() {
            _isLoading = false;
            _statusMessage =
                'Bluetooth sedang nonaktif. Silakan aktifkan Bluetooth.';
          });
          return;
        }

        if (state is UnsupportedBluetoothState) {
          setState(() {
            _isLoading = false;
            _statusMessage = 'Perangkat ini tidak mendukung Bluetooth printer.';
          });
          return;
        }

        if (state is UnknownState) {
          setState(() {
            _isLoading = false;
            _statusMessage = 'Memindai perangkat Bluetooth...';
          });
        }
      });
    });

    Future<void>.delayed(const Duration(seconds: 7), () {
      if (!mounted) {
        return;
      }

      if (_isLoading) {
        setState(() {
          _isLoading = false;
          _statusMessage ??= 'Tidak menemukan perangkat. Coba scan ulang.';
        });
      }
    });
  }

  @override
  void dispose() {
    _discoverySubscription?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final devices =
        _devicesByAddress.values
            .where((device) {
              if (_query.isEmpty) {
                return true;
              }

              final name = device.name.toLowerCase();
              final address = device.macAddress.toLowerCase();
              return name.contains(_query) || address.contains(_query);
            })
            .toList(growable: false)
          ..sort((a, b) {
            final byName = a.name.toLowerCase().compareTo(b.name.toLowerCase());
            if (byName != 0) {
              return byName;
            }
            return a.macAddress.compareTo(b.macAddress);
          });

    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFF3F6FB)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(22),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.bluetooth_searching_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cari Printer Bluetooth',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pilih perangkat untuk mulai mencetak invoice',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withAlpha(210),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'Cari nama printer / MAC address',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(child: _buildDeviceBody(devices)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await openAppSettings();
                      },
                      icon: const Icon(Icons.settings_rounded),
                      label: const Text('Open Settings'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Tutup'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceBody(List<PrinterDevice> devices) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            SizedBox(height: 10),
            Text('Memindai perangkat...'),
          ],
        ),
      );
    }

    if (devices.isEmpty) {
      return Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Text(
            _statusMessage ??
                'Belum ada printer ditemukan. Pastikan printer sudah menyala dan dalam mode pairing.',
            style: const TextStyle(color: Color(0xFF92400E), height: 1.3),
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: devices.length,
      separatorBuilder: (_, itemIndex) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final device = devices[index];
        final displayName = device.name.isEmpty
            ? 'Unknown Printer'
            : device.name;

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => Navigator.pop(context, device),
            child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.print_rounded,
                      color: Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          device.macAddress,
                          style: const TextStyle(
                            color: Color(0xFF475569),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
