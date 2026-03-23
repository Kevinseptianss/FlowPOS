part of 'cart_bloc.dart';

sealed class CartState extends Equatable {
  const CartState();

  @override
  List<Object> get props => [];
}

final class CartLoaded extends CartState {
  final List<Cart> items;
  final int totalAmount;

  const CartLoaded(this.items, this.totalAmount);

  @override
  List<Object> get props => [items, totalAmount];
}

final class CartEmpty extends CartState {
  const CartEmpty();

  @override
  List<Object> get props => [];
}
