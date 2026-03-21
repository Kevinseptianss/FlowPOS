part of 'menu_item_bloc.dart';

sealed class MenuItemState extends Equatable {
  const MenuItemState();

  @override
  List<Object> get props => [];
}

final class MenuItemInitial extends MenuItemState {}

final class MenuItemLoading extends MenuItemState {}

final class MenuItemLoaded extends MenuItemState {
  final List<MenuItem> menuItems;

  const MenuItemLoaded(this.menuItems);

  @override
  List<Object> get props => [menuItems];
}

final class MenuItemFailure extends MenuItemState {
  final String message;

  const MenuItemFailure(this.message);

  @override
  List<Object> get props => [message];
}
