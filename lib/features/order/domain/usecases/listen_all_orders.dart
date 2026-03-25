import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/repositories/order_repository.dart';
import 'package:fpdart/fpdart.dart';

class ListenAllOrders {
  final OrderRepository orderRepository;

  const ListenAllOrders(this.orderRepository);

  Stream<Either<Failure, List<OrderEntity>>> call() {
    return orderRepository.listenAllOrders();
  }
}
