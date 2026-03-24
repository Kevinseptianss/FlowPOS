import 'package:equatable/equatable.dart';

class OrderEntity extends Equatable {
  final String id;
  final String orderNumber;
  final int tableNumber;
  final int total;
  final String paymentId;
  final String paymentMethod;

  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.tableNumber,
    required this.total,
    required this.paymentId,
    required this.paymentMethod,
  });

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    tableNumber,
    total,
    paymentId,
    paymentMethod,
  ];
}
