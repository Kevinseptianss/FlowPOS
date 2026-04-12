import 'package:equatable/equatable.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/order/domain/entities/monthly_revenue.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/order/domain/usecases/create_order.dart';
import 'package:flow_pos/features/order/domain/usecases/get_all_orders.dart';
import 'package:flow_pos/features/order/domain/usecases/get_monthly_revenue.dart';
import 'package:flow_pos/features/order/domain/usecases/get_revenue_range.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'order_event.dart';
part 'order_state.dart';

class OrderBloc extends Bloc<OrderEvent, OrderState> {
  final CreateOrder _createOrder;
  final GetMonthlyRevenue _getMonthlyRevenue;
  final GetRevenueRange _getRevenueRange;
  final GetAllOrders _getAllOrders;

  OrderBloc({
    required CreateOrder createOrder,
    required GetMonthlyRevenue getMonthlyRevenue,
    required GetRevenueRange getRevenueRange,
    required GetAllOrders getAllOrders,
  }) : _createOrder = createOrder,
       _getMonthlyRevenue = getMonthlyRevenue,
       _getRevenueRange = getRevenueRange,
       _getAllOrders = getAllOrders,
       super(OrderInitial()) {
    on<CreateOrderEvent>(_onCreateOrder);
    on<GetMonthlyRevenueEvent>(_onGetMonthlyRevenue);
    on<GetRevenueRangeEvent>(_onGetRevenueRange);
    on<GetAllOrdersEvent>(_onGetAllOrders);
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
}
