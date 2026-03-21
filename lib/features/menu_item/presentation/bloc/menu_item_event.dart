part of 'menu_item_bloc.dart';

sealed class MenuItemEvent extends Equatable {
  const MenuItemEvent();

  @override
  List<Object> get props => [];
}

final class GetAllMenuItemsEvent extends MenuItemEvent {}
