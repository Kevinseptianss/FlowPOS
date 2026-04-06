import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

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
  static const String _rawBtPackageId = 'ru.a402d.rawbtprinter';
  static const String _rawBtVirtualAddress = 'rawbt://service';
  static const int _lineWidth = 32;

  PrinterDevice? _selectedDevice;

  @override
  Future<PrinterDevice?> selectDevice({required BuildContext context}) async {
    _ensureAndroidOnly();

    return const PrinterDevice(
      name: 'RawBT',
      macAddress: _rawBtVirtualAddress,
      isPaired: true,
    );
  }

  @override
  Future<List<PrinterDevice>> getPairedDevices() async {
    _ensureAndroidOnly();

    return const [
      PrinterDevice(
        name: 'RawBT',
        macAddress: _rawBtVirtualAddress,
        isPaired: true,
      ),
    ];
  }

  @override
  Future<List<PrinterDevice>> discoverNearbyDevices({
    Duration timeout = const Duration(seconds: 8),
  }) {
    return getPairedDevices();
  }

  @override
  Future<bool> pairDevice({required String macAddress}) async {
    return true;
  }

  @override
  Future<bool> get isConnected async {
    return _selectedDevice != null;
  }

  @override
  Future<void> connect({required String macAddress}) async {
    _ensureAndroidOnly();

    _selectedDevice = const PrinterDevice(
      name: 'RawBT',
      macAddress: _rawBtVirtualAddress,
      isPaired: true,
    );
  }

  @override
  Future<void> printTestReceipt({
    required BuildContext context,
    required StoreSettings storeSettings,
    required String cashierName,
  }) async {
    final now = DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    final receipt = <String>[
      _center(storeSettings.storeName),
      _center(storeSettings.storeAddress),
      _divider('='),
      _center('TEST PRINT'),
      _center('Jika teks ini tercetak'),
      _center('printer siap dipakai.'),
      _divider(),
      'Kasir: $cashierName',
      'Waktu: $now',
      _divider('='),
      _center('FLOW POS'),
      '',
    ].join('\n');

    await _printRawText(receipt);
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

    final lines = <String>[
      _center(storeSettings.storeName),
      _center(storeSettings.storeAddress),
      _divider(),
      'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}',
      'Kasir  : $cashierName',
      'Table  : T${order.tableNumber}',
      _divider(),
    ];

    for (final item in order.items) {
      lines.addAll(_buildOrderItemLines(item));
    }

    lines.add(_divider());
    lines.add(_kv('Sub Total', formatRupiah(subtotal)));
    lines.add(
      _kv(
        'Tax (${_formatPercentage(storeSettings.taxPercentage)})',
        formatRupiah(taxAmount),
      ),
    );

    if (serviceAmount > 0) {
      lines.add(
        _kv(
          'Service (${_formatPercentage(storeSettings.serviceChargePercentage)})',
          formatRupiah(serviceAmount),
        ),
      );
    }

    lines.add(
      _kv(
        'Bayar (${order.payment.method.toUpperCase()})',
        formatRupiah(order.payment.amountPaid),
      ),
    );
    lines.add(_kv('Kembali', formatRupiah(order.payment.changeGiven)));
    lines.add(_divider('='));
    lines.add(_center('Terima kasih'));
    lines.add('');

    await _printRawText(lines.join('\n'));
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

    final lines = <String>[
      _center(storeSettings.storeName),
      _center(storeSettings.storeAddress),
      _divider('='),
      _center('LAPORAN TUTUP KASIR'),
      _center('TRANSAKSI PENJUALAN'),
      _divider(),
      'Kasir      : $cashierName',
      'Waktu Buka : ${_formatShiftDateTime(openedAt)}',
      'Waktu Tutup: ${_formatShiftDateTime(closedAt)}',
      _divider(),
      _kv('Modal Awal', formatRupiah(openingBalance)),
      _kv('CASH', formatRupiah(totalCashSales)),
      _kv('QRIS', formatRupiah(totalQrisSales)),
      if (totalCashIn > 0) _kv('Kas Masuk', formatRupiah(totalCashIn)),
      if (totalCashOut > 0) _kv('Kas Keluar', formatRupiah(totalCashOut)),
      _kv('Total Penerimaan', formatRupiah(totalPenerimaan)),
      _kv('Saldo Akhir', formatRupiah(saldoAkhir)),
      _kv('Transaksi masuk', '$totalTransactions'),
      _divider('='),
      '',
      _center('LAPORAN TUTUP KASIR'),
      _center('PENJUALAN MENU'),
      _divider(),
      'Kasir      : $cashierName',
      'Waktu Buka : ${_formatShiftDateTime(openedAt)}',
      'Waktu Tutup: ${_formatShiftDateTime(closedAt)}',
      _divider(),
      'Produk Terjual',
      _divider(),
    ];

    if (soldProducts.isEmpty) {
      lines.add('Tidak ada data penjualan menu');
    } else {
      for (final item in soldProducts) {
        lines.add(_kv(item.name, '[${item.quantity}]'));
      }
    }

    lines.add(_divider());
    lines.add(_kv('Total', '[$totalProdukTerjual]'));
    lines.add('');

    await _printRawText(lines.join('\n'));
  }

  Future<void> _printRawText(String content) async {
    _ensureAndroidOnly();

    if (_selectedDevice == null) {
      throw Exception('Printer is not connected.');
    }

    final intentUri = _buildIntentUri(content);
    final rawTextUri = _buildRawTextUri(content);
    final rawBase64Uri = _buildRawBase64Uri(content);

    if (await launchUrl(intentUri, mode: LaunchMode.externalApplication)) {
      return;
    }

    if (await launchUrl(rawBase64Uri, mode: LaunchMode.externalApplication)) {
      return;
    }

    if (await launchUrl(rawTextUri, mode: LaunchMode.externalApplication)) {
      return;
    }

    final marketUri = Uri.parse('market://details?id=$_rawBtPackageId');
    if (await canLaunchUrl(marketUri)) {
      await launchUrl(marketUri, mode: LaunchMode.externalApplication);
    }

    throw Exception(
      'RawBT app is not available. Install RawBT first and set it as default print service.',
    );
  }

  Uri _buildIntentUri(String content) {
    final encoded = Uri.encodeComponent(content);

    return Uri.parse(
      'intent:$encoded#Intent;scheme=rawbt;package=$_rawBtPackageId;end',
    );
  }

  Uri _buildRawTextUri(String content) {
    return Uri.parse('rawbt:${Uri.encodeComponent(content)}');
  }

  Uri _buildRawBase64Uri(String content) {
    final base64Content = base64Encode(utf8.encode(content));
    return Uri.parse('rawbt:base64,$base64Content');
  }

  void _ensureAndroidOnly() {
    if (!Platform.isAndroid) {
      throw Exception('RawBT printing is currently supported on Android only.');
    }
  }

  List<String> _buildOrderItemLines(OrderItem item) {
    final lines = <String>[];
    final itemName = item.menuName.trim();
    lines.addAll(_wrap(itemName.isEmpty ? 'Unknown menu' : itemName));

    final modifier = (item.modifierSnapshot ?? '').trim();
    if (modifier.isNotEmpty) {
      lines.addAll(_wrap('Modifier: $modifier'));
    }

    final notes = (item.notes ?? '').trim();
    if (notes.isNotEmpty) {
      lines.addAll(_wrap('Notes: $notes'));
    }

    final subtotal = item.quantity * item.unitPrice;
    final compactPrice = _toCompactRupiah(item.unitPrice);
    lines.add(_kv('${item.quantity}x$compactPrice', formatRupiah(subtotal)));

    return lines;
  }

  String _center(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    if (trimmed.length >= _lineWidth) {
      return trimmed;
    }

    final totalPadding = _lineWidth - trimmed.length;
    final left = totalPadding ~/ 2;
    final right = totalPadding - left;

    return '${' ' * left}$trimmed${' ' * right}';
  }

  String _divider([String char = '-']) {
    return List<String>.filled(_lineWidth, char).join();
  }

  String _kv(String left, String right) {
    final cleanLeft = left.trim();
    final cleanRight = right.trim();

    if (cleanRight.isEmpty) {
      return cleanLeft;
    }

    final reservedSpacing = 1;
    final maxLeftWidth = _lineWidth - cleanRight.length - reservedSpacing;
    if (maxLeftWidth <= 0) {
      return '$cleanLeft $cleanRight';
    }

    final fitLeft = cleanLeft.length > maxLeftWidth
        ? '${cleanLeft.substring(0, maxLeftWidth - 1)}…'
        : cleanLeft;

    final spaces = _lineWidth - fitLeft.length - cleanRight.length;
    return '$fitLeft${' ' * spaces}$cleanRight';
  }

  List<String> _wrap(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      return const [];
    }

    final words = text.split(RegExp(r'\s+'));
    final wrapped = <String>[];
    var current = '';

    for (final word in words) {
      if (word.length >= _lineWidth) {
        if (current.isNotEmpty) {
          wrapped.add(current);
          current = '';
        }

        var remaining = word;
        while (remaining.length > _lineWidth) {
          wrapped.add(remaining.substring(0, _lineWidth));
          remaining = remaining.substring(_lineWidth);
        }

        if (remaining.isNotEmpty) {
          current = remaining;
        }
        continue;
      }

      if (current.isEmpty) {
        current = word;
        continue;
      }

      final candidate = '$current $word';
      if (candidate.length <= _lineWidth) {
        current = candidate;
      } else {
        wrapped.add(current);
        current = word;
      }
    }

    if (current.isNotEmpty) {
      wrapped.add(current);
    }

    return wrapped;
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
