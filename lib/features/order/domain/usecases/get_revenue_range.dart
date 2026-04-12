import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/order/domain/entities/monthly_revenue.dart';
import 'package:flow_pos/features/order/domain/repositories/order_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetRevenueRange implements UseCase<MonthlyRevenue, GetRevenueRangeParams> {
  final OrderRepository orderRepository;

  const GetRevenueRange(this.orderRepository);

  @override
  Future<Either<Failure, MonthlyRevenue>> call(
    GetRevenueRangeParams params,
  ) async {
    return await orderRepository.getRevenueRange(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

class GetRevenueRangeParams {
  final DateTime startDate;
  final DateTime endDate;

  const GetRevenueRangeParams({
    required this.startDate,
    required this.endDate,
  });
}
