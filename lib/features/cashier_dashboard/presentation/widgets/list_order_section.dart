import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/cashier_dashboard/domain/entities/cart.dart';
import 'package:flow_pos/features/cashier_dashboard/domain/entities/selected_modifier.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/cart_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/table_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/qty_button.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/summary_row.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListOrderSection extends StatelessWidget {
  const ListOrderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, orderState) {
        if (orderState is OrderCreated) {
          showSnackbar(context, 'Order created successfully!');
          // Clear cart after successful order
          context.read<CartBloc>().add(const ClearCartEvent());
          // Close the bottom sheet
          Navigator.of(context).pop();
        } else if (orderState is OrderFailure) {
          showSnackbar(context, orderState.message);
        }
      },
      child: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartEmpty) {
            return Container(
              color: AppPallete.surface,
              padding: const EdgeInsets.all(16),
              child: const Center(child: Text('Cart is empty')),
            );
          }

          if (state is CartLoaded) {
            const int taxRate = 10;
            const int serviceChargeRate = 5;
            final int subtotal = state.totalAmount;
            final int tax = (subtotal * taxRate) ~/ 100;
            final int serviceCharge = (subtotal * serviceChargeRate) ~/ 100;
            final int total = subtotal + tax + serviceCharge;

            return Container(
              color: AppPallete.surface,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppPallete.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: state.items.length,
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return _OrderItemTile(
                          cartItem: item,
                          onQuantityChanged: (newQuantity) {
                            context.read<CartBloc>().add(
                              UpdateCartItemQuantityEvent(item.id, newQuantity),
                            );
                          },
                          onRemove: () {
                            context.read<CartBloc>().add(
                              RemoveFromCartEvent(item.id),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppPallete.divider),
                  const SizedBox(height: 8),
                  SummaryRow(label: 'Subtotal', value: subtotal),
                  const SizedBox(height: 6),
                  SummaryRow(label: 'Tax ($taxRate%)', value: tax),
                  const SizedBox(height: 6),
                  SummaryRow(
                    label: 'Service ($serviceChargeRate%)',
                    value: serviceCharge,
                  ),
                  const SizedBox(height: 8),
                  const Divider(color: AppPallete.divider),
                  const SizedBox(height: 8),
                  SummaryRow(label: 'Total', value: total, isTotal: true),
                  const SizedBox(height: 16),
                  BlocBuilder<OrderBloc, OrderState>(
                    builder: (context, state) {
                      if (state is OrderLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _createOrder(context, 'QRIS', total),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppPallete.primary,
                                foregroundColor: AppPallete.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('QRIS'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _createOrder(context, 'CASH', total),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppPallete.secondary,
                                foregroundColor: AppPallete.onPrimary,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('CASH'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          }

          return const SizedBox();
        },
      ),
    );
  }

  void _createOrder(BuildContext context, String method, int total) {
    final cartBloc = context.read<CartBloc>();
    final orderBloc = context.read<OrderBloc>();
    final tableBloc = context.read<TableBloc>();
    final userBloc = context.read<UserBloc>();

    final cartState = cartBloc.state;
    if (cartState is! CartLoaded) return;

    final userState = userBloc.state;
    if (userState is! UserLoggedIn) {
      showSnackbar(context, 'User not logged in');
      return;
    }

    // Generate order number (timestamp-based)
    final now = DateTime.now();
    final orderNumber =
        'ORD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

    // Build order items from cart
    final orderItems = cartState.items.map((cartItem) {
      // Serialize modifiers for snapshot (just names since prices are included in unit_price)
      final modifierSnapshot = cartItem.selectedModifiers.values
          .whereType<SelectedModifier>()
          .map((modifier) => modifier.name)
          .join(', ');

      return OrderItem(
        menuItemId: cartItem.menuItemId,
        quantity: cartItem.quantity,
        unitPrice: (cartItem.basePrice + _modifiersUnitPrice(cartItem))
            .toInt(), // Include modifier price
        notes: null, // Could be added later for special instructions
        modifierSnapshot: modifierSnapshot.isNotEmpty ? modifierSnapshot : null,
      );
    }).toList();

    // Calculate amounts
    const int taxRate = 10;
    const int serviceChargeRate = 5;
    final int subtotal = cartState.totalAmount;

    // For QRIS, amount paid equals total
    // For CASH, we'll assume exact payment for now (could be made configurable later)
    final int amountPaid = method == 'QRIS' ? total : total;

    orderBloc.add(
      CreateOrderEvent(
        orderNumber: orderNumber,
        tableNumber: tableBloc.state.selectedTableNumber,
        cashierId: userState.user.id,
        subtotal: subtotal,
        tax: taxRate.toDouble(),
        serviceCharge: serviceChargeRate.toDouble(),
        total: total,
        method: method,
        amountPaid: amountPaid,
        items: orderItems,
      ),
    );
  }

  int _modifiersUnitPrice(Cart item) {
    if (item.quantity <= 0) return 0;

    final perUnitPrice = item.totalPrice ~/ item.quantity;
    final modifiersUnitPrice = perUnitPrice - item.basePrice;

    return modifiersUnitPrice < 0 ? 0 : modifiersUnitPrice;
  }
}

class _OrderItemTile extends StatelessWidget {
  final Cart cartItem;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const _OrderItemTile({
    required this.cartItem,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final selectedModifierNames = cartItem.selectedModifiers.values
        .whereType<SelectedModifier>()
        .map((modifier) => modifier.name)
        .where((name) => name.trim().isNotEmpty)
        .toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPallete.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Item name and delete button
          Row(
            children: [
              Expanded(
                child: Text(
                  cartItem.name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPallete.textPrimary,
                  ),
                  softWrap: true,
                  maxLines: null,
                ),
              ),
              IconButton(
                onPressed: onRemove,
                icon: const Icon(Icons.delete, color: AppPallete.error),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Row 2: Price and modifiers
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rp ${cartItem.basePrice}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppPallete.textPrimary),
              ),
              // Show selected modifiers
              if (selectedModifierNames.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Modifiers: ${selectedModifierNames.join(', ')}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPallete.textPrimary,
                    ),
                    softWrap: true,
                    maxLines: null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 3: Quantity controls and total price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  QtyButton(
                    icon: Icons.remove,
                    onTap: () => onQuantityChanged(cartItem.quantity - 1),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${cartItem.quantity}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPallete.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  QtyButton(
                    icon: Icons.add,
                    onTap: () => onQuantityChanged(cartItem.quantity + 1),
                  ),
                ],
              ),
              Text(
                'Rp ${cartItem.totalPrice}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPallete.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
