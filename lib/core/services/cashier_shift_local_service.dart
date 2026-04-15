import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class CashierShiftLocalService {
  static const Duration _wibOffset = Duration(hours: 7);

  final Box<dynamic> _box;
  final FirebaseFirestore _firestore;

  CashierShiftLocalService(this._box, this._firestore);

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

  String _skipShiftKey(String cashierId) => 'skipped_shift_$cashierId';

  Future<void> setShiftSkipped(String cashierId, bool skipped) async {
    await _box.put(_skipShiftKey(cashierId), skipped);
  }

  bool isShiftSkipped(String cashierId) {
    return _box.get(_skipShiftKey(cashierId), defaultValue: false) as bool;
  }

  Future<void> clearShiftSkipped(String cashierId) async {
    await _box.delete(_skipShiftKey(cashierId));
  }

  Stream<BoxEvent> watchActiveShift(String cashierId) {
    return _box.watch(key: _activeShiftKey(cashierId));
  }

  dynamic listenable() => _box.listenable();

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



  Future<void> openShift({
    required String shiftId,
    required String cashierId,
    required String cashierName,
    required double openingBalance,
    DateTime? openedAt,
  }) async {
    final openedAtUtc = openedAt?.toUtc() ?? _utcNow();

    await _box.put(_activeShiftKey(cashierId), {
      'shiftId': shiftId,
      'cashierId': cashierId,
      'cashierName': cashierName,
      'openingBalance': openingBalance,
      'openedAtUtc': openedAtUtc.toIso8601String(),
      'openedAt': _toWibIso8601(openedAtUtc),
      'syncStatus': 'opened_local',
    });
  }

  String? getActiveShiftId(String cashierId) {
    final shift = getActiveShift(cashierId);
    return shift?['shiftId'] as String?;
  }

  Future<Map<String, int>> calculateShiftTotals({
    required String cashierId,
    required DateTime openedAtUtc,
    required DateTime closedAtUtc,
  }) async {
    final orderSnapshot = await _firestore
        .collection('orders')
        .where('cashier_id', isEqualTo: cashierId)
        .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(openedAtUtc))
        .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(closedAtUtc))
        .get();

    var totalCashSales = 0;
    var totalQrisSales = 0;

    for (final doc in orderSnapshot.docs) {
      final data = doc.data();
      if (data['status'] == 'VOIDED') continue;
      
      final payment = data['payment'] as Map<String, dynamic>?;
      if (payment == null) continue;

      final method = (payment['method'] as String? ?? '').trim().toUpperCase();
      final amountDue = (payment['amount_due'] as num?)?.toInt() ?? 0;

      if (method == 'QRIS') {
        totalQrisSales += amountDue;
      } else if (method == 'CASH') {
        totalCashSales += amountDue;
      }
    }

    return {
      'totalCashSales': totalCashSales,
      'totalQrisSales': totalQrisSales,
    };
  }

  Future<void> clearActiveShift(String cashierId) async {
    await _box.delete(_activeShiftKey(cashierId));
  }
}
