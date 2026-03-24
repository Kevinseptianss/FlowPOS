import 'package:equatable/equatable.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/order/domain/usecases/create_order.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'order_event.dart';
part 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final CreateOrder _createOrder;

  OrderBloc({required CreateOrder createOrder})
    : _createOrder = createOrder,
      super(OrderInitial()) {
    on<CreateOrderEvent>(_onCreateOrder);
  }

  void _onCreateOrder(CreateOrderEvent event, Emitter<OrderState> emit) async {
    emit(OrderLoading());

    final result = await _createOrder(
      CreateOrderParams(
        orderNumber: event.orderNumber,
        tableNumber: event.tableNumber,
        cashierId: event.cashierId,
        subtotal: event.subtotal,
        tax: event.tax,
        serviceCharge: event.serviceCharge,
        total: event.total,
        method: event.method,
        amountPaid: event.amountPaid,
        items: event.items,
      ),
    );

    result.fold(
      (l) => emit(OrderFailure(l.message)),
      (r) => emit(OrderCreated(r)),
    );
  }
}
