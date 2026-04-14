import 'package:equatable/equatable.dart';

class ShiftEntity extends Equatable {
  final String id;
  final String cashierId;
  final String? cashierName; // Joined from profiles
  final DateTime openedAt;
  final DateTime? closedAt;
  final int openingBalance;
  final int? closingBalance;
  final int totalCashSales;
  final int totalQrisSales;
  final int totalCashIn;
  final int totalCashOut;

  const ShiftEntity({
    required this.id,
    required this.cashierId,
    this.cashierName,
    required this.openedAt,
    this.closedAt,
    required this.openingBalance,
    this.closingBalance,
    this.totalCashSales = 0,
    this.totalQrisSales = 0,
    this.totalCashIn = 0,
    this.totalCashOut = 0,
  });

  bool get isClosed => closedAt != null;

  int get expectedClosingBalance => openingBalance + totalCashSales + totalCashIn - totalCashOut;
  
  int get variance => (closingBalance ?? 0) - expectedClosingBalance;

  @override
  List<Object?> get props => [
    id, cashierId, cashierName, openedAt, closedAt, 
    openingBalance, closingBalance, totalCashSales, 
    totalQrisSales, totalCashIn, totalCashOut
  ];
}
