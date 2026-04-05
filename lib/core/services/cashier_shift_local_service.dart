import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CashierShiftLocalService {
  static const Duration _wibOffset = Duration(hours: 7);

  final Box<dynamic> _box;
  final SupabaseClient _supabaseClient;
  final Uuid _uuid = const Uuid();

  CashierShiftLocalService(this._box, this._supabaseClient);

  String _activeShiftKey(String cashierId) => 'active_shift_$cashierId';

  Map<String, dynamic>? getActiveShift(String cashierId) {
    final value = _box.get(_activeShiftKey(cashierId));

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  bool hasActiveShift(String cashierId) {
    return getActiveShift(cashierId) != null;
  }

  Stream<BoxEvent> watchActiveShift(String cashierId) {
    return _box.watch(key: _activeShiftKey(cashierId));
  }

  DateTime _utcNow() => DateTime.now().toUtc();

  String _toWibIso8601(DateTime utcDateTime) {
    final wibDateTime = utcDateTime.toUtc().add(_wibOffset);

    String twoDigits(int value) => value.toString().padLeft(2, '0');
    String threeDigits(int value) => value.toString().padLeft(3, '0');
    final year = wibDateTime.year.toString().padLeft(4, '0');

    return '$year-${twoDigits(wibDateTime.month)}-${twoDigits(wibDateTime.day)}T'
        '${twoDigits(wibDateTime.hour)}:${twoDigits(wibDateTime.minute)}:${twoDigits(wibDateTime.second)}.'
        '${threeDigits(wibDateTime.millisecond)}+07:00';
  }

  DateTime? _parseOpenedAtUtc(Map<String, dynamic> activeShift) {
    final openedAtUtcRaw = activeShift['openedAtUtc'] as String?;
    final openedAtUtc = DateTime.tryParse(openedAtUtcRaw ?? '')?.toUtc();
    if (openedAtUtc != null) {
      return openedAtUtc;
    }

    final legacyOpenedAtRaw = activeShift['openedAt'] as String?;
    final legacyOpenedAt = DateTime.tryParse(legacyOpenedAtRaw ?? '');
    if (legacyOpenedAt == null) {
      return null;
    }

    return legacyOpenedAt.toUtc();
  }

  Future<void> openShift({
    required String cashierId,
    required String cashierName,
    required double openingBalance,
  }) async {
    final openedAtUtc = _utcNow();

    await _box.put(_activeShiftKey(cashierId), {
      'cashierId': cashierId,
      'cashierName': cashierName,
      'openingBalance': openingBalance,
      'openedAtUtc': openedAtUtc.toIso8601String(),
      'openedAt': _toWibIso8601(openedAtUtc),
      'syncStatus': 'opened_local',
    });
  }

  Future<Map<String, dynamic>?> closeShift({required String cashierId}) async {
    final activeShift = getActiveShift(cashierId);

    if (activeShift == null) {
      return null;
    }

    final openedAtUtc = _parseOpenedAtUtc(activeShift);
    final closedAtUtc = _utcNow();

    if (openedAtUtc == null) {
      throw Exception('Invalid shift open time. Please reopen shift.');
    }

    final orderRows = await _supabaseClient
        .from('orders')
        .select('''
          id,
          payments (
            method,
            amount_due
          )
        ''')
        .eq('cashier_id', cashierId)
        .gte('created_at', openedAtUtc.toIso8601String())
        .lte('created_at', closedAtUtc.toIso8601String());

    // =======================================================
    // 🔍 DEBUGGING POINT: Cek hasil query di Terminal/Console
    // =======================================================
    print('--- DEBUG CLOSE SHIFT ---');
    print('Opened At (UTC): ${openedAtUtc.toIso8601String()}');
    print('Closed At (UTC): ${closedAtUtc.toIso8601String()}');
    print('Jumlah Order Ditemukan: ${orderRows.length}');
    print('Data Order: $orderRows');
    print('-------------------------');

    var totalCashSales = 0;
    var totalQrisSales = 0;

    for (final row in orderRows) {
      final paymentRows = row['payments'] as List<dynamic>? ?? [];
      if (paymentRows.isEmpty) {
        continue;
      }

      final payment = paymentRows.first as Map<String, dynamic>;
      final method = (payment['method'] as String? ?? '').trim().toUpperCase();
      final amountDue = (payment['amount_due'] as num?)?.toInt() ?? 0;

      if (method == 'QRIS') {
        totalQrisSales += amountDue;
      } else if (method == 'CASH') {
        totalCashSales += amountDue;
      }
    }

    const totalCashIn = 0;
    const totalCashOut = 0;
    final openingBalance =
        (activeShift['openingBalance'] as num?)?.toInt() ?? 0;
    final closingBalance =
        openingBalance + totalCashSales + totalCashIn - totalCashOut;

    await _supabaseClient.from('shifts').insert({
      'id': _uuid.v4(),
      'cashier_id': cashierId,
      'opened_at': openedAtUtc.toIso8601String(),
      'closed_at': closedAtUtc.toIso8601String(),
      'opening_balance': openingBalance,
      'closing_balance': closingBalance,
      'total_cash_sales': totalCashSales,
      'total_qris_sales': totalQrisSales,
      'total_cash_in': totalCashIn,
      'total_cash_out': totalCashOut,
    });

    final closedShift = <String, dynamic>{
      ...activeShift,
      'openedAtUtc': openedAtUtc.toIso8601String(),
      'openedAt': _toWibIso8601(openedAtUtc),
      'closedAtUtc': closedAtUtc.toIso8601String(),
      'closedAt': _toWibIso8601(closedAtUtc),
      'syncStatus': 'uploaded',
      'totalCashSales': totalCashSales,
      'totalQrisSales': totalQrisSales,
      'totalCashIn': totalCashIn,
      'totalCashOut': totalCashOut,
      'closingBalance': closingBalance,
    };

    await _box.delete(_activeShiftKey(cashierId));

    return closedShift;
  }
}
