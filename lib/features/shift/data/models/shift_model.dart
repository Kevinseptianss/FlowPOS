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
      openedAt: DateTime.parse(json['opened_at'] as String),
      closedAt: json['closed_at'] != null 
          ? DateTime.parse(json['closed_at'] as String) 
          : null,
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
}
