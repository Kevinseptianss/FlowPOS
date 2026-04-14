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
  final String? shiftId;
  final String? status;
  final String? customerName;
  final String? paymentLink;

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
    this.shiftId,
    this.status,
    this.customerName,
    this.paymentLink,
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
    if (shiftId != null) shiftId!,
    if (status != null) status!,
    if (customerName != null) customerName!,
    if (paymentLink != null) paymentLink!,
  ];
}

final class GetMonthlyRevenueEvent extends OrderEvent {
  final DateTime month;

  const GetMonthlyRevenueEvent({required this.month});

  @override
  List<Object> get props => [month];
}

final class GetAllOrdersEvent extends OrderEvent {}

final class GetRevenueRangeEvent extends OrderEvent {
  final DateTime startDate;
  final DateTime endDate;

  const GetRevenueRangeEvent({required this.startDate, required this.endDate});

  @override
  List<Object> get props => [startDate, endDate];
}

final class SoftDeleteOrderItemEvent extends OrderEvent {
  final String orderItemId;
  final String deletedById;

  const SoftDeleteOrderItemEvent({
    required this.orderItemId,
    required this.deletedById,
  });

  @override
  List<Object> get props => [orderItemId, deletedById];
}

final class SettleOrderEvent extends OrderEvent {
  final String orderId;
  final String method;
  final int amountPaid;
  final int amountDue;
  final int changeGiven;

  const SettleOrderEvent({
    required this.orderId,
    required this.method,
    required this.amountPaid,
    required this.amountDue,
    required this.changeGiven,
  });

  @override
  List<Object> get props => [
    orderId,
    method,
    amountPaid,
    amountDue,
    changeGiven,
  ];
}

final class VoidOrderEvent extends OrderEvent {
  final String orderId;

  const VoidOrderEvent({required this.orderId});

  @override
  List<Object> get props => [orderId];
}
