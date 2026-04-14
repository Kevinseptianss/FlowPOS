import 'package:equatable/equatable.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/order/domain/entities/monthly_revenue.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/order/domain/repositories/order_repository.dart';
import 'package:flow_pos/features/order/domain/usecases/create_order.dart';
import 'package:flow_pos/features/order/domain/usecases/get_all_orders.dart';
import 'package:flow_pos/features/order/domain/usecases/get_monthly_revenue.dart';
import 'package:flow_pos/features/order/domain/usecases/get_revenue_range.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'order_event.dart';
part 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final CreateOrder _createOrder;
  final GetMonthlyRevenue _getMonthlyRevenue;
  final GetRevenueRange _getRevenueRange;
  final GetAllOrders _getAllOrders;
  final OrderRepository _orderRepository;

  OrderBloc({
    required CreateOrder createOrder,
    required GetMonthlyRevenue getMonthlyRevenue,
    required GetRevenueRange getRevenueRange,
    required GetAllOrders getAllOrders,
    required OrderRepository orderRepository,
  }) : _createOrder = createOrder,
       _getMonthlyRevenue = getMonthlyRevenue,
       _getRevenueRange = getRevenueRange,
       _getAllOrders = getAllOrders,
       _orderRepository = orderRepository,
       super(OrderInitial()) {
    on<CreateOrderEvent>(_onCreateOrder);
    on<GetMonthlyRevenueEvent>(_onGetMonthlyRevenue);
    on<GetRevenueRangeEvent>(_onGetRevenueRange);
    on<GetAllOrdersEvent>(_onGetAllOrders);
    on<SoftDeleteOrderItemEvent>(_onSoftDeleteOrderItem);
    on<SettleOrderEvent>(_onSettleOrder);
    on<VoidOrderEvent>(_onVoidOrder);
  }

  void _onVoidOrder(
    VoidOrderEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    final result = await _orderRepository.voidOrder(event.orderId);

    result.fold(
      (l) => emit(OrderFailure(l.message)),
      (_) => add(GetAllOrdersEvent()), // Refresh orders
    );
  }

  void _onSoftDeleteOrderItem(
    SoftDeleteOrderItemEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    final result = await _orderRepository.softDeleteOrderItem(
      orderItemId: event.orderItemId,
      deletedById: event.deletedById,
    );

    result.fold(
      (l) => emit(OrderFailure(l.message)),
      (_) => add(GetAllOrdersEvent()), // Refresh orders
    );
  }

  void _onSettleOrder(
    SettleOrderEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderLoading());
    final result = await _orderRepository.settleOrder(
      orderId: event.orderId,
      method: event.method,
      amountPaid: event.amountPaid,
      amountDue: event.amountDue,
      changeGiven: event.changeGiven,
    );

    result.fold(
      (l) => emit(OrderFailure(l.message)),
      (_) {
        emit(OrderSettled(event.orderId));
        add(GetAllOrdersEvent()); // Refresh orders
      },
    );
  }

  void _onGetRevenueRange(
    GetRevenueRangeEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderRevenueLoading());

    final result = await _getRevenueRange(
      GetRevenueRangeParams(
        startDate: event.startDate,
        endDate: event.endDate,
      ),
    );

    result.fold(
      (l) => emit(OrderFailure(l.message)),
      (r) => emit(OrderRevenueLoaded(r)),
    );
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
        shiftId: event.shiftId,
        status: event.status ?? 'UNPAID',
        customerName: event.customerName,
        paymentLink: event.paymentLink,
      ),
    );

    result.fold(
      (l) {
        debugPrint('--- [ORDER CREATE ERROR] ---');
        debugPrint(l.message);
        debugPrint('-----------------------------');
        emit(OrderFailure(l.message));
      },
      (r) {
        emit(OrderCreated(r));
        add(GetAllOrdersEvent()); // Refresh history list
      },
    );
  }

  void _onGetMonthlyRevenue(
    GetMonthlyRevenueEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrderRevenueLoading());

    final result = await _getMonthlyRevenue(
      GetMonthlyRevenueParams(month: event.month),
    );

    result.fold(
      (l) => emit(OrderFailure(l.message)),
      (r) => emit(OrderRevenueLoaded(r)),
    );
  }

  void _onGetAllOrders(
    GetAllOrdersEvent event,
    Emitter<OrderState> emit,
  ) async {
    emit(OrdersLoading());

    final result = await _getAllOrders(NoParams());

    result.fold(
      (l) => emit(OrderFailure(l.message)),
      (r) => emit(OrdersLoaded(r)),
    );
  }
}
