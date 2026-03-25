import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/order/domain/entities/monthly_revenue.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/order/domain/usecases/create_order.dart';
import 'package:flow_pos/features/order/domain/usecases/get_all_orders.dart';
import 'package:flow_pos/features/order/domain/usecases/get_monthly_revenue.dart';
import 'package:flow_pos/features/order/domain/usecases/listen_all_orders.dart';
import 'package:flow_pos/features/order/domain/usecases/listen_monthly_revenue.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'order_event.dart';
part 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final CreateOrder _createOrder;
  final GetMonthlyRevenue _getMonthlyRevenue;
  final GetAllOrders _getAllOrders;
  final ListenMonthlyRevenue _listenMonthlyRevenue;
  final ListenAllOrders _listenAllOrders;

  StreamSubscription? _monthlyRevenueSubscription;
  StreamSubscription? _allOrdersSubscription;

  OrderBloc({
    required CreateOrder createOrder,
    required GetMonthlyRevenue getMonthlyRevenue,
    required GetAllOrders getAllOrders,
    required ListenMonthlyRevenue listenMonthlyRevenue,
    required ListenAllOrders listenAllOrders,
  }) : _createOrder = createOrder,
       _getMonthlyRevenue = getMonthlyRevenue,
       _getAllOrders = getAllOrders,
       _listenMonthlyRevenue = listenMonthlyRevenue,
       _listenAllOrders = listenAllOrders,
       super(OrderInitial()) {
    on<CreateOrderEvent>(_onCreateOrder);
    on<GetMonthlyRevenueEvent>(_onGetMonthlyRevenue);
    on<GetAllOrdersEvent>(_onGetAllOrders);
    on<StartMonthlyRevenueRealtimeEvent>(_onStartMonthlyRevenueRealtime);
    on<StartAllOrdersRealtimeEvent>(_onStartAllOrdersRealtime);
    on<StopOrderRealtimeEvent>(_onStopOrderRealtime);
    on<MonthlyRevenueRealtimeUpdatedEvent>(_onMonthlyRevenueRealtimeUpdated);
    on<OrdersRealtimeUpdatedEvent>(_onOrdersRealtimeUpdated);
    on<OrderRealtimeFailureEvent>(_onOrderRealtimeFailure);
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

  void _onStartMonthlyRevenueRealtime(
    StartMonthlyRevenueRealtimeEvent event,
    Emitter<OrderState> emit,
  ) async {
    await _monthlyRevenueSubscription?.cancel();
    emit(OrderRevenueLoading());

    _monthlyRevenueSubscription = _listenMonthlyRevenue(month: event.month)
        .listen((result) {
          result.fold(
            (failure) => add(OrderRealtimeFailureEvent(failure.message)),
            (revenue) => add(MonthlyRevenueRealtimeUpdatedEvent(revenue)),
          );
        });
  }

  void _onStartAllOrdersRealtime(
    StartAllOrdersRealtimeEvent event,
    Emitter<OrderState> emit,
  ) async {
    await _allOrdersSubscription?.cancel();
    emit(OrdersLoading());

    _allOrdersSubscription = _listenAllOrders().listen((result) {
      result.fold(
        (failure) => add(OrderRealtimeFailureEvent(failure.message)),
        (orders) => add(OrdersRealtimeUpdatedEvent(orders)),
      );
    });
  }

  void _onStopOrderRealtime(
    StopOrderRealtimeEvent event,
    Emitter<OrderState> emit,
  ) async {
    await _monthlyRevenueSubscription?.cancel();
    await _allOrdersSubscription?.cancel();
    _monthlyRevenueSubscription = null;
    _allOrdersSubscription = null;
  }

  void _onMonthlyRevenueRealtimeUpdated(
    MonthlyRevenueRealtimeUpdatedEvent event,
    Emitter<OrderState> emit,
  ) {
    emit(OrderRevenueLoaded(event.revenue));
  }

  void _onOrdersRealtimeUpdated(
    OrdersRealtimeUpdatedEvent event,
    Emitter<OrderState> emit,
  ) {
    emit(OrdersLoaded(event.orders));
  }

  void _onOrderRealtimeFailure(
    OrderRealtimeFailureEvent event,
    Emitter<OrderState> emit,
  ) {
    emit(OrderFailure(event.message));
  }

  @override
  Future<void> close() async {
    await _monthlyRevenueSubscription?.cancel();
    await _allOrdersSubscription?.cancel();
    return super.close();
  }
}
