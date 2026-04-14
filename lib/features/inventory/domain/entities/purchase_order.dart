import 'package:equatable/equatable.dart';

class PurchaseOrder extends Equatable {
  final String id;
  final String supplierName;
  final int totalAmount;
  final String status;
  final DateTime createdAt;
  final List<PurchaseOrderItem> items;

  const PurchaseOrder({
    required this.id,
    required this.supplierName,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.items = const [],
  });

  @override
  List<Object?> get props => [id, supplierName, totalAmount, status, createdAt, items];
}

class PurchaseOrderItem extends Equatable {
  final String id;
  final String stockId;
  final String itemName;
  final double quantity;
  final int pricePerUnit;

  const PurchaseOrderItem({
    required this.id,
    required this.stockId,
    required this.itemName,
    required this.quantity,
    required this.pricePerUnit,
  });

  @override
  List<Object?> get props => [id, stockId, itemName, quantity, pricePerUnit];
}
