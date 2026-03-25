part of 'order_bloc.dart';

sealed class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object> get props => [];
}

final class OrderInitial extends OrderState {}

final class OrderLoading extends OrderState {}

final class OrderCreated extends OrderState {
  final OrderEntity order;

  const OrderCreated(this.order);

  @override
  List<Object> get props => [order];
}

final class OrderRevenueLoading extends OrderState {}

final class OrderRevenueLoaded extends OrderState {
  final MonthlyRevenue revenue;

  const OrderRevenueLoaded(this.revenue);

  @override
  List<Object> get props => [revenue];
}

final class OrdersLoading extends OrderState {}

final class OrdersLoaded extends OrderState {
  final List<OrderEntity> orders;

  const OrdersLoaded(this.orders);

  @override
  List<Object> get props => [orders];
}

final class OrderFailure extends OrderState {
  final String message;

  const OrderFailure(this.message);

  @override
  List<Object> get props => [message];
}
