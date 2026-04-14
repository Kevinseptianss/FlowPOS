import 'package:flow_pos/features/order/domain/entities/order_entity.dart';

class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.orderNumber,
    required super.tableNumber,
    super.subtotal = 0,
    super.tax = 0,
    super.serviceCharge = 0,
    required super.total,
    required super.createdAt,
    super.payment,
    required super.items,
    super.shiftId,
    super.status = 'PAID',
    super.customerName,
  });
}
