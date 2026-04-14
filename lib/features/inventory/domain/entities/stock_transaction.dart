import 'package:equatable/equatable.dart';

class StockTransaction extends Equatable {
  final String id;
  final String stockId;
  final String type; // IN, OUT, ADJUSTMENT
  final String reason; // PURCHASE, SALE, WASTE, CORRECTION
  final double amount;
  final String? referenceId;
  final DateTime createdAt;

  const StockTransaction({
    required this.id,
    required this.stockId,
    required this.type,
    required this.reason,
    required this.amount,
    this.referenceId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, stockId, type, reason, amount, referenceId, createdAt];
}
