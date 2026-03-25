import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/repositories/order_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetAllOrders implements UseCase<List<OrderEntity>, NoParams> {
  final OrderRepository orderRepository;

  const GetAllOrders(this.orderRepository);

  @override
  Future<Either<Failure, List<OrderEntity>>> call(NoParams params) async {
    return await orderRepository.getAllOrders();
  }
}