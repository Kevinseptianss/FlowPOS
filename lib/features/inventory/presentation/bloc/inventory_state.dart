part of 'inventory_bloc.dart';

abstract class InventoryState extends Equatable {
  const InventoryState();
  
  @override
  List<Object?> get props => [];
}

class InventoryInitial extends InventoryState {}

class InventoryLoading extends InventoryState {}

class InventoryLoaded extends InventoryState {
  final List<Stock> stocks;
  const InventoryLoaded(this.stocks);

  @override
  List<Object?> get props => [stocks];
}

class InventoryFailure extends InventoryState {
  final String message;
  const InventoryFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class PurchaseOrderCreated extends InventoryState {
  final PurchaseOrder purchaseOrder;
  const PurchaseOrderCreated(this.purchaseOrder);

  @override
  List<Object?> get props => [purchaseOrder];
}

class StockHistoryLoading extends InventoryState {}

class StockHistoryLoaded extends InventoryState {
  final List<StockTransaction> transactions;
  const StockHistoryLoaded(this.transactions);

  @override
  List<Object?> get props => [transactions];
}

class PurchaseOrderDetailLoaded extends InventoryState {
  final PurchaseOrder po;
  const PurchaseOrderDetailLoaded(this.po);

  @override
  List<Object?> get props => [po];
}

class OrderDetailLoaded extends InventoryState {
  final OrderEntity order;
  const OrderDetailLoaded(this.order);

  @override
  List<Object?> get props => [order];
}
