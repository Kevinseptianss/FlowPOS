import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:flutter/material.dart';
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
  Future<void> disconnect();
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
  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  @override
  Future<PrinterDevice?> selectDevice({required BuildContext context}) async {
    _ensureAndroidOnly();

    final hasPermission = await _requestPermissions();
    if (!hasPermission) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin Bluetooth diperlukan untuk mencari printer.'),
          ),
        );
      }
      return null;
    }

    final List<BluetoothDevice> pairedDevices = await _bluetooth
        .getBondedDevices();
    final devices = pairedDevices
        .map(
          (d) => PrinterDevice(
            name: d.name ?? 'Unknown',
            macAddress: d.address ?? '',
            isPaired: true,
          ),
        )
        .toList();

    if (!context.mounted) return null;

    final result = await showDialog<PrinterDevice>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Printer Bluetooth'),
          content: SizedBox(
            width: double.maxFinite,
            child: devices.isEmpty
                ? const Text('Tidak ada printer berpasangan ditemukan.')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: devices.length,
                    itemBuilder: (context, index) {
                      final device = devices[index];
                      return ListTile(
                        leading: const Icon(Icons.print_rounded),
                        title: Text(device.name),
                        subtitle: Text(device.macAddress),
                        onTap: () => Navigator.pop(context, device),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
          ],
        );
      },
    );

    return result;
  }

  @override
  Future<List<PrinterDevice>> getPairedDevices() async {
    _ensureAndroidOnly();
    if (!await _requestPermissions()) return [];
    final paired = await _bluetooth.getBondedDevices();
    return paired
        .map(
          (d) => PrinterDevice(
            name: d.name ?? 'Unknown',
            macAddress: d.address ?? '',
            isPaired: true,
          ),
        )
        .toList();
  }

  @override
  Future<List<PrinterDevice>> discoverNearbyDevices({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (!await _requestPermissions()) return [];
    // blue_thermal_printer focus on paired devices usually
    return getPairedDevices();
  }

  @override
  Future<bool> pairDevice({required String macAddress}) async {
    return true; // Use system bluetooth settings for pairing
  }

  @override
  Future<bool> get isConnected async {
    return await _bluetooth.isConnected ?? false;
  }

  @override
  Future<void> connect({required String macAddress}) async {
    _ensureAndroidOnly();
    final isConnected = await _bluetooth.isConnected ?? false;
    if (isConnected) return;

    final devices = await _bluetooth.getBondedDevices();
    final device = devices.firstWhere(
      (d) => d.address == macAddress,
      orElse: () => throw Exception('Printer tidak ditemukan dipasang.'),
    );

    await _bluetooth.connect(device);
  }

  @override
  Future<void> disconnect() async {
    await _bluetooth.disconnect();
  }

  @override
  Future<void> printTestReceipt({
    required BuildContext context,
    required StoreSettings storeSettings,
    required String cashierName,
  }) async {
    final now = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.setStyles(
      const PosStyles(
        bold: true,
        align: PosAlign.center,
        height: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      storeSettings.storeName,
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.setStyles(const PosStyles(align: PosAlign.center));
    bytes += generator.text(
      storeSettings.storeAddress,
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(1);
    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'TEST PRINT',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Printer siap digunakan!',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      '--------------------------------',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text('Kasir: $cashierName');
    bytes += generator.text('Waktu: $now');
    bytes += generator.feed(2);
    bytes += generator.cut();

    await _printBytes(bytes);
  }

  @override
  Future<void> printOrderReceipt({
    required BuildContext context,
    required OrderEntity order,
    required StoreSettings storeSettings,
    required String cashierName,
  }) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    final subtotal = order.items.fold<int>(
      0,
      (sum, item) => sum + (item.quantity * item.unitPrice),
    );
    final taxAmount = ((subtotal * storeSettings.taxPercentage) / 100).round();
    final serviceAmount =
        ((subtotal * storeSettings.serviceChargePercentage) / 100).round();

    bytes += generator.text(
      storeSettings.storeName,
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      storeSettings.storeAddress,
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text('--------------------------------');
    bytes += generator.text('No: ${order.orderNumber}');
    bytes += generator.text('Meja: ${order.tableNumber}');
    if (order.customerName != null && order.customerName!.isNotEmpty) {
      bytes += generator.text('Nama: ${order.customerName}');
    }
    bytes += generator.text('Kasir: $cashierName');
    bytes += generator.text(
      'Waktu: ${DateFormat('dd MMM yyyy, HH:mm').format(order.createdAt)}',
    );
    bytes += generator.text('--------------------------------');

    for (final item in order.items) {
      bytes += generator.text(
        item.menuName,
        styles: const PosStyles(bold: true),
      );
      if (item.modifierSnapshot != null && item.modifierSnapshot!.isNotEmpty) {
        bytes += generator.text(
          ' - ${item.modifierSnapshot}',
          styles: const PosStyles(fontType: PosFontType.fontB),
        );
      }
      bytes += generator.row([
        PosColumn(
          text: '${item.quantity} x ${formatRupiah(item.unitPrice)}',
          width: 6,
        ),
        PosColumn(
          text: formatRupiah(item.quantity * item.unitPrice),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }

    bytes += generator.text('--------------------------------');
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 6),
      PosColumn(
        text: formatRupiah(subtotal),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(
        text: 'Pajak (${storeSettings.taxPercentage.toInt()}%)',
        width: 6,
      ),
      PosColumn(
        text: formatRupiah(taxAmount),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    if (serviceAmount > 0) {
      bytes += generator.row([
        PosColumn(
          text: 'Layanan (${storeSettings.serviceChargePercentage.toInt()}%)',
          width: 6,
        ),
        PosColumn(
          text: formatRupiah(serviceAmount),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    bytes += generator.row([
      PosColumn(text: 'Total', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: formatRupiah(order.total),
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    bytes += generator.text('--------------------------------');
    if (order.payment != null) {
      bytes += generator.row([
        PosColumn(text: order.payment!.method.toUpperCase(), width: 6),
        PosColumn(
          text: formatRupiah(order.payment!.amountPaid),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.row([
        PosColumn(text: 'Kembali', width: 6),
        PosColumn(
          text: formatRupiah(order.payment!.changeGiven),
          width: 6,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    } else {
      bytes += generator.text(
        'PAYMENT PENDING',
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
    }
    bytes += generator.feed(1);
    bytes += generator.text(
      'Terima Kasih',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(2);
    bytes += generator.cut();

    await _printBytes(bytes);
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
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    bytes += generator.text(
      storeSettings.storeName,
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'LAPORAN TUTUP KASIR',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text('--------------------------------');
    bytes += generator.text('Kasir: $cashierName');
    bytes += generator.text(
      'Buka : ${DateFormat('dd/MM HH:mm').format(openedAt)}',
    );
    bytes += generator.text(
      'Tutup: ${DateFormat('dd/MM HH:mm').format(closedAt)}',
    );
    bytes += generator.text('--------------------------------');
    bytes += generator.row([
      PosColumn(text: 'Saldo Awal', width: 6),
      PosColumn(
        text: formatRupiah(openingBalance),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Total CASH', width: 6),
      PosColumn(
        text: formatRupiah(totalCashSales),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Total QRIS', width: 6),
      PosColumn(
        text: formatRupiah(totalQrisSales),
        width: 6,
        styles: const PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.text('--------------------------------');
    bytes += generator.row([
      PosColumn(
        text: 'Saldo Akhir',
        width: 6,
        styles: const PosStyles(bold: true),
      ),
      PosColumn(
        text: formatRupiah(closingBalance),
        width: 6,
        styles: const PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);
    bytes += generator.feed(1);
    bytes += generator.text(
      'RINGKASAN MENU',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );

    for (final item in soldProducts) {
      bytes += generator.row([
        PosColumn(text: item.name, width: 8),
        PosColumn(
          text: 'x ${item.quantity}',
          width: 4,
          styles: const PosStyles(align: PosAlign.right),
        ),
      ]);
    }
    bytes += generator.feed(2);
    bytes += generator.cut();

    await _printBytes(bytes);
  }

  Future<void> _printBytes(List<int> bytes) async {
    _ensureAndroidOnly();
    final isConnected = await _bluetooth.isConnected ?? false;
    if (!isConnected) {
      throw Exception('Printer tidak terhubung.');
    }

    await _bluetooth.writeBytes(Uint8List.fromList(bytes));
  }

  void _ensureAndroidOnly() {
    if (!Platform.isAndroid) {
      throw Exception('Pencetakan thermal saat ini hanya didukung di Android.');
    }
  }

  Future<bool> _requestPermissions() async {
    if (!Platform.isAndroid) return true;

    // For Android 12 (API 31) and higher
    // Needs BLUETOOTH_SCAN, BLUETOOTH_CONNECT
    // For older versions, needs ACCESS_FINE_LOCATION

    final Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    // For Android 12+, bluetoothConnect is the primary permission for bonded devices
    // For older versions, location is often required for Bluetooth operations
    return statuses[Permission.bluetoothConnect]?.isGranted == true ||
        statuses[Permission.location]?.isGranted == true ||
        statuses[Permission.bluetoothScan]?.isGranted == true;
  }
}
