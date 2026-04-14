import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/inventory/domain/entities/purchase_order.dart';
import 'package:flow_pos/features/inventory/domain/entities/stock.dart';
import 'package:flow_pos/features/inventory/domain/entities/stock_transaction.dart';
import 'package:flow_pos/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:flow_pos/features/inventory/domain/usecases/adjust_stock.dart';
import 'package:flow_pos/features/inventory/domain/usecases/create_purchase_order.dart';
import 'package:flow_pos/features/inventory/domain/usecases/get_stock_levels.dart';
import 'package:flow_pos/features/inventory/domain/usecases/get_stock_history.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/repositories/order_repository.dart';

part 'inventory_event.dart';
part 'inventory_state.dart';

class InventoryBloc extends Bloc<InventoryEvent, InventoryState> {
  final GetStockLevels _getStockLevels;
  final AdjustStock _adjustStock;
  final CreatePurchaseOrder _createPurchaseOrder;
  final GetStockHistory _getStockHistory;
  final InventoryRepository _inventoryRepository;
  final OrderRepository _orderRepository;

  InventoryBloc({
    required GetStockLevels getStockLevels,
    required AdjustStock adjustStock,
    required CreatePurchaseOrder createPurchaseOrder,
    required GetStockHistory getStockHistory,
    required InventoryRepository inventoryRepository,
    required OrderRepository orderRepository,
  })  : _getStockLevels = getStockLevels,
        _adjustStock = adjustStock,
        _createPurchaseOrder = createPurchaseOrder,
        _getStockHistory = getStockHistory,
        _inventoryRepository = inventoryRepository,
        _orderRepository = orderRepository,
        super(InventoryInitial()) {
    on<GetStockLevelsEvent>(_onGetStockLevels);
    on<AdjustStockEvent>(_onAdjustStock);
    on<CreatePurchaseOrderEvent>(_onCreatePurchaseOrder);
    on<GetStockHistoryEvent>(_onGetStockHistory);
    on<GetPurchaseOrderEvent>(_onGetPurchaseOrder);
    on<GetOrderByIdEvent>(_onGetOrderById);
  }

  Future<void> _onGetStockLevels(
    GetStockLevelsEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    final res = await _getStockLevels(NoParams());
    res.fold(
      (l) => emit(InventoryFailure(l.message)),
      (r) => emit(InventoryLoaded(r)),
    );
  }

  Future<void> _onAdjustStock(
    AdjustStockEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    final res = await _adjustStock(AdjustStockParams(
      stockId: event.stockId,
      amount: event.amount,
      reason: event.reason,
    ));
    
    res.fold(
      (l) => emit(InventoryFailure(l.message)),
      (r) {
        add(GetStockLevelsEvent());
      },
    );
  }

  Future<void> _onCreatePurchaseOrder(
    CreatePurchaseOrderEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    final res = await _createPurchaseOrder(CreatePurchaseOrderParams(
      supplierName: event.supplierName,
      items: event.items,
    ));
    
    res.fold(
      (l) => emit(InventoryFailure(l.message)),
      (r) {
        emit(PurchaseOrderCreated(r));
        add(GetStockLevelsEvent());
      },
    );
  }

  Future<void> _onGetStockHistory(
    GetStockHistoryEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(StockHistoryLoading());
    final res = await _getStockHistory(event.stockId);
    res.fold(
      (l) => emit(InventoryFailure(l.message)),
      (r) => emit(StockHistoryLoaded(r)),
    );
  }

  Future<void> _onGetPurchaseOrder(
    GetPurchaseOrderEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    final res = await _inventoryRepository.getPurchaseOrder(event.poId);
    res.fold(
      (l) => emit(InventoryFailure(l.message)),
      (r) => emit(PurchaseOrderDetailLoaded(r)),
    );
  }

  Future<void> _onGetOrderById(
    GetOrderByIdEvent event,
    Emitter<InventoryState> emit,
  ) async {
    emit(InventoryLoading());
    final res = await _orderRepository.getOrderById(event.orderId);
    res.fold(
      (l) => emit(InventoryFailure(l.message)),
      (r) => emit(OrderDetailLoaded(r)),
    );
  }
}
