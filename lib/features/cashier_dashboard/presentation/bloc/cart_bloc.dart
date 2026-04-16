import 'package:flow_pos/features/cashier_dashboard/domain/entities/cart.dart';
import 'package:flow_pos/features/cashier_dashboard/domain/entities/selected_modifier.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

part 'cart_event.dart';
part 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final _uuid = const Uuid();

  CartBloc() : super(const CartEmpty()) {
    on<AddToCartEvent>(_onAddToCart);
    on<RemoveFromCartEvent>(_onRemoveFromCart);
    on<UpdateCartItemQuantityEvent>(_onUpdateCartItemQuantity);
    on<ClearCartEvent>(_onClearCart);
    on<ReplaceCartItemsEvent>(_onReplaceCartItems);
  }

  void _onReplaceCartItems(
    ReplaceCartItemsEvent event,
    Emitter<CartState> emit,
  ) {
    if (event.items.isEmpty) {
      emit(const CartEmpty());
    } else {
      final totalAmount = event.items.fold<int>(
        0,
        (sum, item) => sum + item.totalPrice,
      );
      emit(CartLoaded(List.from(event.items), totalAmount));
    }
  }

  void _onAddToCart(AddToCartEvent event, Emitter<CartState> emit) {
    final currentState = state;
    final List<Cart> currentItems;

    if (currentState is CartLoaded) {
      currentItems = List.from(currentState.items);
    } else {
      currentItems = [];
    }

    // Check if item with same menuItemId, same modifiers, AND same notes already exists
    final existingIndex = currentItems.indexWhere(
      (item) =>
          item.menuItemId == event.menuItemId &&
          item.notes == event.notes &&
          _modifiersEqual(item.selectedModifiers, event.selectedModifiers),
    );

    if (existingIndex != -1) {
      // Update quantity of existing item
      final existingItem = currentItems[existingIndex];
      final newQuantity = existingItem.quantity + event.quantity;
      final modifiersUnitPrice = _modifiersUnitPrice(existingItem);
      final newTotalPrice =
          (existingItem.basePrice + modifiersUnitPrice) * newQuantity;

      currentItems[existingIndex] = existingItem.copyWith(
        quantity: newQuantity,
        totalPrice: newTotalPrice,
      );
    } else {
      // Add new item
      final newItem = Cart(
        id: _uuid.v4(),
        menuItemId: event.menuItemId,
        name: event.name,
        basePrice: event.basePrice,
        quantity: event.quantity,
        selectedModifiers: event.selectedModifiers,
        totalPrice: event.totalPrice,
        variantId: event.variantId,
        notes: event.notes,
      );
      currentItems.add(newItem);
    }

    final totalAmount = currentItems.fold<int>(
      0,
      (sum, item) => sum + item.totalPrice,
    );
    emit(CartLoaded(currentItems, totalAmount));
  }

  void _onRemoveFromCart(RemoveFromCartEvent event, Emitter<CartState> emit) {
    if (state is! CartLoaded) return;

    final currentItems = List<Cart>.from((state as CartLoaded).items);
    currentItems.removeWhere((item) => item.id == event.cartItemId);

    if (currentItems.isEmpty) {
      emit(const CartEmpty());
    } else {
      final totalAmount = currentItems.fold<int>(
        0,
        (sum, item) => sum + item.totalPrice,
      );
      emit(CartLoaded(currentItems, totalAmount));
    }
  }

  void _onUpdateCartItemQuantity(
    UpdateCartItemQuantityEvent event,
    Emitter<CartState> emit,
  ) {
    if (state is! CartLoaded) return;

    final currentItems = List<Cart>.from((state as CartLoaded).items);
    final itemIndex = currentItems.indexWhere(
      (item) => item.id == event.cartItemId,
    );

    if (itemIndex != -1) {
      final item = currentItems[itemIndex];
      if (event.newQuantity <= 0) {
        currentItems.removeAt(itemIndex);
      } else {
        final modifiersPrice = _modifiersUnitPrice(item);
        final newTotalPrice =
            (item.basePrice + modifiersPrice) * event.newQuantity;
        currentItems[itemIndex] = item.copyWith(
          quantity: event.newQuantity,
          totalPrice: newTotalPrice,
        );
      }

      if (currentItems.isEmpty) {
        emit(const CartEmpty());
      } else {
        final totalAmount = currentItems.fold<int>(
          0,
          (sum, item) => sum + item.totalPrice,
        );
        emit(CartLoaded(currentItems, totalAmount));
      }
    }
  }

  void _onClearCart(ClearCartEvent event, Emitter<CartState> emit) {
    emit(const CartEmpty());
  }

  bool _modifiersEqual(
    Map<String, SelectedModifier?> a,
    Map<String, SelectedModifier?> b,
  ) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      final aModifier = a[key];
      final bModifier = b[key];
      if (aModifier?.id != bModifier?.id) return false;
    }
    return true;
  }

  int _modifiersUnitPrice(Cart item) {
    if (item.quantity <= 0) return 0;

    final perUnitPrice = item.totalPrice ~/ item.quantity;
    final modifiersUnitPrice = perUnitPrice - item.basePrice;

    return modifiersUnitPrice < 0 ? 0 : modifiersUnitPrice;
  }
}
