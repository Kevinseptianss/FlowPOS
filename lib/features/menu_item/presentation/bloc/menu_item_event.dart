part of 'menu_item_bloc.dart';

sealed class MenuItemEvent extends Equatable {
  const MenuItemEvent();

  @override
  List<Object> get props => [];
}

final class GetAllMenuItemsEvent extends MenuItemEvent {}

final class GetEnabledMenuItemsEvent extends MenuItemEvent {}

final class UpdateMenuItemAvailabilityEvent extends MenuItemEvent {
  final String menuItemId;
  final bool enabled;

  const UpdateMenuItemAvailabilityEvent({
    required this.menuItemId,
    required this.enabled,
  });

  @override
  List<Object> get props => [menuItemId, enabled];
}

final class CreateMenuItemEvent extends MenuItemEvent {
  final String name;
  final int price;
  final int basePrice;
  final String categoryId;
  final String unit;
  final bool enabled;
  final List<Map<String, dynamic>> options;

  const CreateMenuItemEvent({
    required this.name,
    required this.price,
    this.basePrice = 0,
    required this.categoryId,
    this.unit = 'pcs',
    this.enabled = true,
    this.options = const [],
  });

  @override
  List<Object> get props => [name, price, basePrice, categoryId, unit, enabled, options];
}

final class UpdateMenuItemEvent extends MenuItemEvent {
  final String id;
  final String name;
  final int price;
  final int basePrice;
  final String categoryId;
  final String unit;
  final bool enabled;
  final List<Map<String, dynamic>> options;

  const UpdateMenuItemEvent({
    required this.id,
    required this.name,
    required this.price,
    this.basePrice = 0,
    required this.categoryId,
    this.unit = 'pcs',
    this.enabled = true,
    this.options = const [],
  });

  @override
  List<Object> get props => [id, name, price, basePrice, categoryId, unit, enabled, options];
}
