import 'package:equatable/equatable.dart';

class ExpenseEntity extends Equatable {
  final String id;
  final int amount;
  final String categoryId;
  final String categoryName;
  final String note;
  final String type; // 'STORE' or 'SHIFT'
  final String cashActionType; // 'CASH_IN' or 'CASH_OUT'
  final String staffId;
  final String staffName;
  final String? shiftId;
  final DateTime createdAt;
  final bool isAdjustment;

  const ExpenseEntity({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.categoryName,
    required this.note,
    required this.type,
    required this.cashActionType,
    required this.staffId,
    required this.staffName,
    this.shiftId,
    required this.createdAt,
    this.isAdjustment = false,
  });

  @override
  List<Object?> get props => [
        id,
        amount,
        categoryId,
        categoryName,
        note,
        type,
        cashActionType,
        staffId,
        staffName,
        shiftId,
        createdAt,
        isAdjustment,
      ];
}
