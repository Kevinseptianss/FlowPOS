part of 'menu_item_bloc.dart';

sealed class MenuItemEvent extends Equatable {
  const MenuItemEvent();

  @override
  List<Object> get props => [];
}

final class GetAllMenuItemsEvent extends MenuItemEvent {}

final class GetEnabledMenuItemsEvent extends MenuItemEvent {}

final class StartMenuItemsRealtimeEvent extends MenuItemEvent {}

final class StartEnabledMenuItemsRealtimeEvent extends MenuItemEvent {}

final class StopMenuItemsRealtimeEvent extends MenuItemEvent {}

final class MenuItemsRealtimeUpdatedEvent extends MenuItemEvent {
  final List<MenuItem> menuItems;

  const MenuItemsRealtimeUpdatedEvent(this.menuItems);

  @override
  List<Object> get props => [menuItems];
}

final class MenuItemsRealtimeFailureEvent extends MenuItemEvent {
  final String message;

  const MenuItemsRealtimeFailureEvent(this.message);

  @override
  List<Object> get props => [message];
}

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
  final String categoryId;

  const CreateMenuItemEvent({
    required this.name,
    required this.price,
    required this.categoryId,
  });

  @override
  List<Object> get props => [name, price, categoryId];
}
