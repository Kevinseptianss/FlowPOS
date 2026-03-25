part of 'order_bloc.dart';

sealed class OrderEvent extends Equatable {
  const OrderEvent();

  @override
  List<Object> get props => [];
}

final class CreateOrderEvent extends OrderEvent {
  final String orderNumber;
  final int tableNumber;
  final String cashierId;
  final int subtotal;
  final double tax;
  final double serviceCharge;
  final int total;
  final String method;
  final int amountPaid;
  final List<OrderItem> items;

  const CreateOrderEvent({
    required this.orderNumber,
    required this.tableNumber,
    required this.cashierId,
    required this.subtotal,
    required this.tax,
    required this.serviceCharge,
    required this.total,
    required this.method,
    required this.amountPaid,
    required this.items,
  });

  @override
  List<Object> get props => [
    orderNumber,
    tableNumber,
    cashierId,
    subtotal,
    tax,
    serviceCharge,
    total,
    method,
    amountPaid,
    items,
  ];
}

final class GetMonthlyRevenueEvent extends OrderEvent {
  final DateTime month;

  const GetMonthlyRevenueEvent({required this.month});

  @override
  List<Object> get props => [month];
}

final class GetAllOrdersEvent extends OrderEvent {}

final class StartMonthlyRevenueRealtimeEvent extends OrderEvent {
  final DateTime month;

  const StartMonthlyRevenueRealtimeEvent({required this.month});

  @override
  List<Object> get props => [month];
}

final class StartAllOrdersRealtimeEvent extends OrderEvent {}

final class StopOrderRealtimeEvent extends OrderEvent {}

final class MonthlyRevenueRealtimeUpdatedEvent extends OrderEvent {
  final MonthlyRevenue revenue;

  const MonthlyRevenueRealtimeUpdatedEvent(this.revenue);

  @override
  List<Object> get props => [revenue];
}

final class OrdersRealtimeUpdatedEvent extends OrderEvent {
  final List<OrderEntity> orders;

  const OrdersRealtimeUpdatedEvent(this.orders);

  @override
  List<Object> get props => [orders];
}

final class OrderRealtimeFailureEvent extends OrderEvent {
  final String message;

  const OrderRealtimeFailureEvent(this.message);

  @override
  List<Object> get props => [message];
}
