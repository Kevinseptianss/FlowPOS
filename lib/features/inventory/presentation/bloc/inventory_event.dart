part of 'inventory_bloc.dart';

abstract class InventoryEvent extends Equatable {
  const InventoryEvent();

  @override
  List<Object?> get props => [];
}

class GetStockLevelsEvent extends InventoryEvent {}

class AdjustStockEvent extends InventoryEvent {
  final String stockId;
  final double amount;
  final String reason;

  const AdjustStockEvent({
    required this.stockId,
    required this.amount,
    required this.reason,
  });

  @override
  List<Object?> get props => [stockId, amount, reason];
}

class CreatePurchaseOrderEvent extends InventoryEvent {
  final String supplierName;
  final List<Map<String, dynamic>> items;

  const CreatePurchaseOrderEvent({
    required this.supplierName,
    required this.items,
  });

  @override
  List<Object?> get props => [supplierName, items];
}

class GetStockHistoryEvent extends InventoryEvent {
  final String stockId;

  const GetStockHistoryEvent(this.stockId);

  @override
  List<Object?> get props => [stockId];
}

class GetPurchaseOrderEvent extends InventoryEvent {
  final String poId;

  const GetPurchaseOrderEvent(this.poId);

  @override
  List<Object?> get props => [poId];
}

class GetOrderByIdEvent extends InventoryEvent {
  final String orderId;

  const GetOrderByIdEvent(this.orderId);

  @override
  List<Object?> get props => [orderId];
}
