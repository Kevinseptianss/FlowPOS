import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flow_pos/features/shift/domain/entities/shift_entity.dart';

class ShiftModel extends ShiftEntity {
  const ShiftModel({
    required super.id,
    required super.cashierId,
    super.cashierName,
    required super.openedAt,
    super.closedAt,
    required super.openingBalance,
    super.closingBalance,
    super.totalCashSales,
    super.totalQrisSales,
    super.totalCashIn,
    super.totalCashOut,
  });

  factory ShiftModel.fromJson(Map<String, dynamic> json) {
    return ShiftModel(
      id: json['id'] as String,
      cashierId: json['cashier_id'] as String,
      cashierName: json['profiles'] is List 
          ? (json['profiles'] as List).first['name'] as String?
          : json['profiles']?['name'] as String?,
      openedAt: _parseDate(json['opened_at']),
      closedAt: json['closed_at'] != null ? _parseDate(json['closed_at']) : null,
      openingBalance: (json['opening_balance'] as num).toInt(),
      closingBalance: json['closing_balance'] != null 
          ? (json['closing_balance'] as num).toInt() 
          : null,
      totalCashSales: (json['total_cash_sales'] as num? ?? 0).toInt(),
      totalQrisSales: (json['total_qris_sales'] as num? ?? 0).toInt(),
      totalCashIn: (json['total_cash_in'] as num? ?? 0).toInt(),
      totalCashOut: (json['total_cash_out'] as num? ?? 0).toInt(),
    );
  }

  static DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.parse(date);
    return DateTime.now();
  }
}
