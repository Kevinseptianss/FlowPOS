import 'package:flow_pos/features/order/domain/entities/order_entity.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.orderNumber,
    required super.tableNumber,
    required super.total,
    required super.paymentId,
    required super.paymentMethod,
  });
}
