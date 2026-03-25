import 'package:equatable/equatable.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/create_menu_item.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/get_all_menu_items.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'menu_item_event.dart';
part 'menu_item_state.dart';

class MenuItemBloc extends Bloc<MenuItemEvent, MenuItemState> {
  final GetAllMenuItems _getAllMenuItems;
  final CreateMenuItem _createMenuItem;

  MenuItemBloc({
    required GetAllMenuItems getAllMenuItems,
    required CreateMenuItem createMenuItem,
  }) : _getAllMenuItems = getAllMenuItems,
       _createMenuItem = createMenuItem,
       super(MenuItemInitial()) {
    on<GetAllMenuItemsEvent>(_onGetAllMenuItems);
    on<CreateMenuItemEvent>(_onCreateMenuItem);
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
}
