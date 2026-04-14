import 'package:equatable/equatable.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/order/domain/entities/payment_entity.dart';

class OrderEntity extends Equatable {
  final String id;
  final String orderNumber;
  final int tableNumber;
  final int? subtotal;
  final int? tax;
  final int? serviceCharge;
  final int total;
  final DateTime createdAt;
  final PaymentEntity? payment;
  final List<OrderItem> items;
  final String? shiftId;
  final String status;

  final String? customerName;

  const OrderEntity({
    required this.id,
    required this.orderNumber,
    required this.tableNumber,
    this.subtotal = 0,
    this.tax = 0,
    this.serviceCharge = 0,
    required this.total,
    required this.createdAt,
    this.payment,
    required this.items,
    this.shiftId,
    this.status = 'PAID',
    this.customerName,
  });

  OrderEntity copyWith({
    String? id,
    String? orderNumber,
    int? tableNumber,
    int? subtotal,
    int? tax,
    int? serviceCharge,
    int? total,
    DateTime? createdAt,
    PaymentEntity? payment,
    List<OrderItem>? items,
    String? shiftId,
    String? status,
    String? customerName,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      tableNumber: tableNumber ?? this.tableNumber,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      payment: payment ?? this.payment,
      items: items ?? this.items,
      shiftId: shiftId ?? this.shiftId,
      status: status ?? this.status,
      customerName: customerName ?? this.customerName,
    );
  }

  int get displaySubtotal {
    if ((subtotal ?? 0) > 0) return subtotal!;
    // Fallback: Sum up items if subtotal is zero (for legacy data)
    return items.fold(0, (sum, item) => sum + (item.quantity * item.unitPrice));
  }

  int get displayTax {
    if ((tax ?? 0) > 0) return tax!;
    // Fallback: If we have subtotal and total, tax+service is the difference
    // But we can't easily split tax and service without more info.
    // For now, just return what's stored.
    return tax ?? 0;
  }

  int get displayServiceCharge {
    if ((serviceCharge ?? 0) > 0) return serviceCharge!;
    return serviceCharge ?? 0;
  }

  @override
  List<Object?> get props => [
    id,
    orderNumber,
    tableNumber,
    subtotal,
    tax,
    serviceCharge,
    total,
    createdAt,
    payment,
    items,
    shiftId,
    status,
    customerName,
  ];
}
