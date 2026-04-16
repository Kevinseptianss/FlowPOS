import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flow_pos/features/expense/domain/entities/expense_entity.dart';

class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.amount,
    required super.categoryId,
    required super.categoryName,
    required super.note,
    required super.type,
    required super.cashActionType,
    required super.staffId,
    required super.staffName,
    super.shiftId,
    required super.createdAt,
    super.isAdjustment,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toInt(),
      categoryId: json['category_id'] as String,
      categoryName: json['category_name'] as String,
      note: json['note'] as String,
      type: json['type'] as String,
      cashActionType: json['cash_action_type'] as String,
      staffId: json['staff_id'] as String,
      staffName: json['staff_name'] as String,
      shiftId: json['shift_id'] as String?,
      createdAt: _parseDate(json['created_at']),
      isAdjustment: json['is_adjustment'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category_id': categoryId,
      'category_name': categoryName,
      'note': note,
      'type': type,
      'cash_action_type': cashActionType,
      'staff_id': staffId,
      'staff_name': staffName,
      'shift_id': shiftId,
      'created_at': Timestamp.fromDate(createdAt),
      'is_adjustment': isAdjustment,
    };
  }

  static DateTime _parseDate(dynamic date) {
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.parse(date);
    return DateTime.now();
  }
}
