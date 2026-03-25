part of 'menu_item_bloc.dart';

sealed class MenuItemEvent extends Equatable {
  const MenuItemEvent();

  @override
  List<Object> get props => [];
}

final class GetAllMenuItemsEvent extends MenuItemEvent {}

final class CreateMenuItemEvent extends MenuItemEvent {
  final String name;
  final int price;
  final String categoryId;

  const CreateMenuItemEvent({
    required this.name,
    required this.price,
    required this.categoryId,
  });

  @override
  List<Object> get props => [name, price, categoryId];
}
