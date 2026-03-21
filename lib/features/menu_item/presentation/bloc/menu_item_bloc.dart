import 'package:equatable/equatable.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';
import 'package:flow_pos/features/menu_item/domain/usecases/get_all_menu_items.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'menu_item_event.dart';
part 'menu_item_state.dart';

class MenuItemBloc extends Bloc<MenuItemEvent, MenuItemState> {
  final GetAllMenuItems _getAllMenuItems;

  MenuItemBloc({required GetAllMenuItems getAllMenuItems})
    : _getAllMenuItems = getAllMenuItems,
      super(MenuItemInitial()) {
    on<GetAllMenuItemsEvent>(_onGetAllMenuItems);
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
}
