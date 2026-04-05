import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:intl/intl.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

class PrinterDevice {
  final String name;
  final String macAddress;

  const PrinterDevice({required this.name, required this.macAddress});
}

abstract interface class ThermalReceiptPrinterService {
  Future<List<PrinterDevice>> getPairedDevices();
  Future<bool> get isConnected;
  Future<void> connect({required String macAddress});
  Future<void> printOrderReceipt({
    required OrderEntity order,
    required StoreSettings storeSettings,
    required String cashierName,
  });
}

class ThermalReceiptPrinterServiceImpl implements ThermalReceiptPrinterService {
  @override
  Future<List<PrinterDevice>> getPairedDevices() async {
    await _ensureBluetoothReady();
    final devices = await PrintBluetoothThermal.pairedBluetooths;

    return devices
        .map(
          (device) =>
              PrinterDevice(name: device.name, macAddress: device.macAdress),
        )
        .toList();
  }

  @override
  Future<bool> get isConnected => PrintBluetoothThermal.connectionStatus;

  @override
  Future<void> connect({required String macAddress}) async {
    await _ensureBluetoothReady();
    final connected = await PrintBluetoothThermal.connect(
      macPrinterAddress: macAddress,
    );

    if (!connected) {
      throw Exception('Failed to connect printer.');
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

  String _formatPercentage(double percentage) {
    if (percentage == percentage.toInt()) {
      return '${percentage.toInt()}%';
    }

    final normalized = percentage.toStringAsFixed(2);
    return '${normalized.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')}%';
  }
}
