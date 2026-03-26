import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/create_menu_item.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/get_all_menu_items.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/listen_all_menu_items.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/update_menu_item_availability.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'menu_item_event.dart';
part 'menu_item_state.dart';

class MenuItemBloc extends Bloc<MenuItemEvent, MenuItemState> {
  final GetAllMenuItems _getAllMenuItems;
  final CreateMenuItem _createMenuItem;
  final ListenAllMenuItems _listenAllMenuItems;
  final UpdateMenuItemAvailability _updateMenuItemAvailability;

  StreamSubscription? _menuItemsSubscription;

  MenuItemBloc({
    required GetAllMenuItems getAllMenuItems,
    required CreateMenuItem createMenuItem,
    required ListenAllMenuItems listenAllMenuItems,
    required UpdateMenuItemAvailability updateMenuItemAvailability,
  }) : _getAllMenuItems = getAllMenuItems,
       _createMenuItem = createMenuItem,
       _listenAllMenuItems = listenAllMenuItems,
       _updateMenuItemAvailability = updateMenuItemAvailability,
       super(MenuItemInitial()) {
    on<GetAllMenuItemsEvent>(_onGetAllMenuItems);
    on<CreateMenuItemEvent>(_onCreateMenuItem);
    on<StartMenuItemsRealtimeEvent>(_onStartMenuItemsRealtime);
    on<StopMenuItemsRealtimeEvent>(_onStopMenuItemsRealtime);
    on<MenuItemsRealtimeUpdatedEvent>(_onMenuItemsRealtimeUpdated);
    on<MenuItemsRealtimeFailureEvent>(_onMenuItemsRealtimeFailure);
    on<UpdateMenuItemAvailabilityEvent>(_onUpdateMenuItemAvailability);
  }

  void _onGetAllMenuItems(
    GetAllMenuItemsEvent event,
    Emitter<MenuItemState> emit,
  ) async {
    emit(MenuItemLoading());

    final result = await _getAllMenuItems(NoParams());

    result.fold(
      (l) => emit(MenuItemFailure(l.message)),
      (r) => emit(MenuItemLoaded(r)),
    );
  }

  void _onCreateMenuItem(
    CreateMenuItemEvent event,
    Emitter<MenuItemState> emit,
  ) async {
    emit(MenuItemLoading());

    final createResult = await _createMenuItem(
      CreateMenuItemParams(
        name: event.name,
        price: event.price,
        categoryId: event.categoryId,
      ),
    );

    final createFailed = createResult.fold<bool>((_) => true, (_) => false);
    if (createFailed) {
      createResult.fold((l) => emit(MenuItemFailure(l.message)), (_) {});
      return;
    }

    final getAllResult = await _getAllMenuItems(NoParams());

    getAllResult.fold(
      (l) => emit(MenuItemFailure(l.message)),
      (r) => emit(MenuItemLoaded(r)),
    );
  }

  void _onStartMenuItemsRealtime(
    StartMenuItemsRealtimeEvent event,
    Emitter<MenuItemState> emit,
  ) async {
    await _menuItemsSubscription?.cancel();
    emit(MenuItemLoading());

    _menuItemsSubscription = _listenAllMenuItems().listen((result) {
      result.fold(
        (failure) => add(MenuItemsRealtimeFailureEvent(failure.message)),
        (menuItems) => add(MenuItemsRealtimeUpdatedEvent(menuItems)),
      );
    });
  }

  void _onStopMenuItemsRealtime(
    StopMenuItemsRealtimeEvent event,
    Emitter<MenuItemState> emit,
  ) async {
    await _menuItemsSubscription?.cancel();
    _menuItemsSubscription = null;
  }

  void _onMenuItemsRealtimeUpdated(
    MenuItemsRealtimeUpdatedEvent event,
    Emitter<MenuItemState> emit,
  ) {
    emit(MenuItemLoaded(event.menuItems));
  }

  void _onMenuItemsRealtimeFailure(
    MenuItemsRealtimeFailureEvent event,
    Emitter<MenuItemState> emit,
  ) {
    emit(MenuItemFailure(event.message));
  }

  void _onUpdateMenuItemAvailability(
    UpdateMenuItemAvailabilityEvent event,
    Emitter<MenuItemState> emit,
  ) async {
    final result = await _updateMenuItemAvailability(
      UpdateMenuItemAvailabilityParams(
        menuItemId: event.menuItemId,
        enabled: event.enabled,
      ),
    );

    result.fold((failure) => emit(MenuItemFailure(failure.message)), (_) {});
  }

  @override
  Future<void> close() async {
    await _menuItemsSubscription?.cancel();
    return super.close();
  }
}
