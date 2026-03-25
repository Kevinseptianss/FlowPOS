import 'package:equatable/equatable.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/order/domain/entities/payment_entity.dart';

class OrderEntity extends Equatable {
  final String id;
  final String orderNumber;
  final int tableNumber;
  final int total;
  final DateTime createdAt;
  final PaymentEntity payment;
  final List<OrderItem> items;

  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.tableNumber,
    required this.total,
    required this.createdAt,
    required this.payment,
    required this.items,
  });

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    tableNumber,
    total,
    createdAt,
    payment,
    items,
  ];
}
