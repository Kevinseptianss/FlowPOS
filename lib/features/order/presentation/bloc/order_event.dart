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
