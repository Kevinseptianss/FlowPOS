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
  });

  Future<Either<Failure, MonthlyRevenue>> getMonthlyRevenue({
    required DateTime month,
  });

  Stream<Either<Failure, MonthlyRevenue>> listenMonthlyRevenue({
    required DateTime month,
  });

  Future<Either<Failure, List<OrderEntity>>> getAllOrders();

  Stream<Either<Failure, List<OrderEntity>>> listenAllOrders();
}
