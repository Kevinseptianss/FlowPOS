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
    String? shiftId,
    String status = 'PAID',
    String? customerName,
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
        shiftId: shiftId,
        status: status,
        customerName: customerName,
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
  Future<Either<Failure, MonthlyRevenue>> getRevenueRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final revenue = await orderRemoteDataSource.getRevenueRange(
        startDate: startDate,
        endDate: endDate,
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

  @override
  Future<Either<Failure, OrderEntity>> getOrderById(String orderId) async {
    try {
      final order = await orderRemoteDataSource.getOrderById(orderId);
      return right(order);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> softDeleteOrderItem({
    required String orderItemId,
    required String deletedById,
  }) async {
    try {
      await orderRemoteDataSource.softDeleteOrderItem(
        orderItemId: orderItemId,
        deletedById: deletedById,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> settleOrder({
    required String orderId,
    required String method,
    required int amountPaid,
    required int amountDue,
    required int changeGiven,
  }) async {
    try {
      await orderRemoteDataSource.settleOrder(
        orderId: orderId,
        method: method,
        amountPaid: amountPaid,
        amountDue: amountDue,
        changeGiven: changeGiven,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> voidOrder(String orderId) async {
    try {
      await orderRemoteDataSource.voidOrder(orderId);
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
