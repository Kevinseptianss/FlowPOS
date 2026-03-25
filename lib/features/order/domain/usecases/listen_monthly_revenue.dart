import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/order/domain/entities/monthly_revenue.dart';
import 'package:flow_pos/features/order/domain/repositories/order_repository.dart';
import 'package:fpdart/fpdart.dart';

class ListenMonthlyRevenue {
  final OrderRepository orderRepository;

  const ListenMonthlyRevenue(this.orderRepository);

  Stream<Either<Failure, MonthlyRevenue>> call({required DateTime month}) {
    return orderRepository.listenMonthlyRevenue(month: month);
  }
}
