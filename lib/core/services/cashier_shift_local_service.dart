import 'package:hive/hive.dart';

class CashierShiftLocalService {
  static const String _pendingClosedShiftsKey = 'pending_closed_shifts';

  final Box<dynamic> _box;

  CashierShiftLocalService(this._box);

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

  Future<void> openShift({
    required String cashierId,
    required String cashierName,
    required double openingBalance,
  }) async {
    await _box.put(_activeShiftKey(cashierId), {
      'cashierId': cashierId,
      'cashierName': cashierName,
      'openingBalance': openingBalance,
      'openedAt': DateTime.now().toIso8601String(),
      'syncStatus': 'opened_local',
    });
  }

  Future<Map<String, dynamic>?> closeShift({required String cashierId}) async {
    final activeShift = getActiveShift(cashierId);

    if (activeShift == null) {
      return null;
    }

    final closedShift = <String, dynamic>{
      ...activeShift,
      'closedAt': DateTime.now().toIso8601String(),
      'syncStatus': 'pending_upload',
    };

    final pendingShifts = getPendingClosedShifts();
    pendingShifts.add(closedShift);

    await _box.put(_pendingClosedShiftsKey, pendingShifts);
    await _box.delete(_activeShiftKey(cashierId));

    return closedShift;
  }

  List<Map<String, dynamic>> getPendingClosedShifts() {
    final value = _box.get(_pendingClosedShiftsKey);

    if (value is! List) {
      return <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
