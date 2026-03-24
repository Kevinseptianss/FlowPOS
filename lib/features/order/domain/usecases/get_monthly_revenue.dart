import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/order/domain/entities/monthly_revenue.dart';
import 'package:flow_pos/features/order/domain/repositories/order_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetMonthlyRevenue
    implements UseCase<MonthlyRevenue, GetMonthlyRevenueParams> {
  final OrderRepository orderRepository;

  const GetMonthlyRevenue(this.orderRepository);

  @override
  Future<Either<Failure, MonthlyRevenue>> call(
    GetMonthlyRevenueParams params,
  ) async {
    if (params.month.year < 2000) {
      return left(const Failure('Invalid month parameter.'));
    }

    return await orderRepository.getMonthlyRevenue(month: params.month);
  }
}

class GetMonthlyRevenueParams {
  final DateTime month;

  const GetMonthlyRevenueParams({required this.month});
}
