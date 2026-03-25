import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/order/data/datasources/order_remote_data_source.dart';
import 'package:flow_pos/features/order/domain/entities/monthly_revenue.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/order/domain/repositories/order_repository.dart';
import 'package:fpdart/fpdart.dart';

class OrderRepositoryImpl implements OrderRepository {
  final OrderRemoteDataSource orderRemoteDataSource;

  OrderRepositoryImpl(this.orderRemoteDataSource);

  @override
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
  }) async {
    try {
      final createdOrder = await orderRemoteDataSource.createOrder(
        orderNumber: orderNumber,
        tableNumber: tableNumber,
        cashierId: cashierId,
        subtotal: subtotal,
        tax: tax,
        serviceCharge: serviceCharge,
        total: total,
        method: method,
        amountPaid: amountPaid,
        items: items,
      );

      return right(createdOrder);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, MonthlyRevenue>> getMonthlyRevenue({
    required DateTime month,
  }) async {
    try {
      final revenue = await orderRemoteDataSource.getMonthlyRevenue(
        month: month,
      );

      return right(revenue);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<OrderEntity>>> getAllOrders() async {
    try {
      final orders = await orderRemoteDataSource.getAllOrders();
      return right(orders);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
