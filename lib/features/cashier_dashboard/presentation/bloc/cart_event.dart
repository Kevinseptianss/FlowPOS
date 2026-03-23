part of 'cart_bloc.dart';

sealed class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object> get props => [];
}

final class AddToCartEvent extends CartEvent {
  final String menuItemId;
  final String name;
  final int basePrice;
  final int quantity;
  final Map<String, SelectedModifier?> selectedModifiers;
  final int totalPrice;

  const AddToCartEvent({
    required this.menuItemId,
    required this.name,
    required this.basePrice,
    required this.quantity,
    required this.selectedModifiers,
    required this.totalPrice,
  });

  @override
  List<Object> get props => [
    menuItemId,
    name,
    basePrice,
    quantity,
    selectedModifiers,
    totalPrice,
  ];
}

final class RemoveFromCartEvent extends CartEvent {
  final String cartItemId;

  const RemoveFromCartEvent(this.cartItemId);

  @override
  List<Object> get props => [cartItemId];
}

final class UpdateCartItemQuantityEvent extends CartEvent {
  final String cartItemId;
  final int newQuantity;

  const UpdateCartItemQuantityEvent(this.cartItemId, this.newQuantity);

  @override
  List<Object> get props => [cartItemId, newQuantity];
}

final class ClearCartEvent extends CartEvent {
  const ClearCartEvent();

  @override
  List<Object> get props => [];
}
