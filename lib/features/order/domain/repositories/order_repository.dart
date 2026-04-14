import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/order/domain/entities/monthly_revenue.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class OrderRepository {
  Future<Either<Failure, OrderEntity>> createOrder({
    required String orderNumber,
    required int tableNumber,
    required String cashierId,
    required int subtotal,
    required double tax,
    required double serviceCharge,
    required int total,
    required String method,
    required int amountPaid,
    required List<OrderItem> items,
    String? shiftId,
    String status = 'UNPAID',
    String? customerName,
    String? paymentLink,
  });

  Future<Either<Failure, MonthlyRevenue>> getMonthlyRevenue({
    required DateTime month,
  });

  Future<Either<Failure, MonthlyRevenue>> getRevenueRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<Either<Failure, List<OrderEntity>>> getAllOrders();
  Future<Either<Failure, OrderEntity>> getOrderById(String orderId);
  Future<Either<Failure, void>> softDeleteOrderItem({
    required String orderItemId,
    required String deletedById,
  });
  Future<Either<Failure, void>> settleOrder({
    required String orderId,
    required String method,
    required int amountPaid,
    required int amountDue,
    required int changeGiven,
  });
  Future<Either<Failure, void>> voidOrder(String orderId);
}
