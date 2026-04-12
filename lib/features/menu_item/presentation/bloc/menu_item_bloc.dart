import 'package:equatable/equatable.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/create_menu_item.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/get_all_menu_items.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/get_enabled_menu_items.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/update_menu_item.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/update_menu_item_availability.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'menu_item_event.dart';
part 'menu_item_state.dart';

class MenuItemBloc extends Bloc<MenuItemEvent, MenuItemState> {
  final GetAllMenuItems _getAllMenuItems;
  final GetEnabledMenuItems _getEnabledMenuItems;
  final CreateMenuItem _createMenuItem;
  final UpdateMenuItem _updateMenuItem;
  final UpdateMenuItemAvailability _updateMenuItemAvailability;

  MenuItemBloc({
    required GetAllMenuItems getAllMenuItems,
    required GetEnabledMenuItems getEnabledMenuItems,
    required CreateMenuItem createMenuItem,
    required UpdateMenuItem updateMenuItem,
    required UpdateMenuItemAvailability updateMenuItemAvailability,
  }) : _getAllMenuItems = getAllMenuItems,
       _getEnabledMenuItems = getEnabledMenuItems,
       _createMenuItem = createMenuItem,
       _updateMenuItem = updateMenuItem,
       _updateMenuItemAvailability = updateMenuItemAvailability,
       super(MenuItemInitial()) {
    on<GetAllMenuItemsEvent>(_onGetAllMenuItems);
    on<GetEnabledMenuItemsEvent>(_onGetEnabledMenuItems);
    on<CreateMenuItemEvent>(_onCreateMenuItem);
    on<UpdateMenuItemEvent>(_onUpdateMenuItem);
    on<UpdateMenuItemAvailabilityEvent>(_onUpdateMenuItemAvailability);
  }

  void _onUpdateMenuItem(
    UpdateMenuItemEvent event,
    Emitter<MenuItemState> emit,
  ) async {
    emit(MenuItemLoading());

    final updateResult = await _updateMenuItem(
      UpdateMenuItemParams(
        id: event.id,
        name: event.name,
        price: event.price,
        categoryId: event.categoryId,
        unit: event.unit,
        options: event.options,
      ),
    );

    final updateFailed = updateResult.fold<bool>((_) => true, (_) => false);
    if (updateFailed) {
      updateResult.fold((l) => emit(MenuItemFailure(l.message)), (_) {});
      return;
    }

    final getAllResult = await _getAllMenuItems(NoParams());

    getAllResult.fold(
      (l) => emit(MenuItemFailure(l.message)),
      (r) => emit(MenuItemLoaded(r)),
    );
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
        unit: event.unit,
        options: event.options,
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

  void _onGetEnabledMenuItems(
    GetEnabledMenuItemsEvent event,
    Emitter<MenuItemState> emit,
  ) async {
    emit(MenuItemLoading());

    final result = await _getEnabledMenuItems(NoParams());

    result.fold(
      (l) => emit(MenuItemFailure(l.message)),
      (r) => emit(MenuItemLoaded(r)),
    );
  }

  void _onUpdateMenuItemAvailability(
    UpdateMenuItemAvailabilityEvent event,
    Emitter<MenuItemState> emit,
  ) async {
    List<MenuItem>? previousMenuItems;

    if (state is MenuItemLoaded) {
      final current = state as MenuItemLoaded;
      previousMenuItems = current.menuItems;

      final optimisticMenuItems = current.menuItems
          .map(
            (item) => item.id == event.menuItemId
                ? MenuItem(
                    id: item.id,
                    name: item.name,
                    price: item.price,
                    category: item.category,
                    enabled: event.enabled,
                    unit: item.unit,
                    variants: item.variants,
                  )
                : item,
          )
          .toList(growable: false);

      emit(MenuItemLoaded(optimisticMenuItems));
    }

    final result = await _updateMenuItemAvailability(
      UpdateMenuItemAvailabilityParams(
        menuItemId: event.menuItemId,
        enabled: event.enabled,
      ),
    );

    result.fold((failure) {
      if (previousMenuItems != null) {
        emit(MenuItemLoaded(previousMenuItems));
      } else {
        emit(MenuItemFailure(failure.message));
      }
    }, (_) {});
  }
}
