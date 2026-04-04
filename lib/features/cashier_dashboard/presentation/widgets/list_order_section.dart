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
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:flow_pos/features/store_settings/presentation/bloc/store_settings_bloc.dart';
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
      child: BlocListener<StoreSettingsBloc, StoreSettingsState>(
        listener: (context, settingsState) {
          if (settingsState is StoreSettingsFailure) {
            showSnackbar(context, settingsState.message);
          }
        },
        child: BlocBuilder<StoreSettingsBloc, StoreSettingsState>(
          builder: (context, settingsState) {
            final storeSettings = settingsState is StoreSettingsLoaded
                ? settingsState.storeSettings
                : const StoreSettings.zero();

            return BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                if (state is CartEmpty) {
                  return Container(
                    color: AppPallete.surface,
                    padding: const EdgeInsets.all(16),
                    child: const Center(child: Text('Cart is empty')),
                  );
                }

                if (state is CartLoaded) {
                  final double taxRate = storeSettings.taxPercentage;
                  final double serviceChargeRate =
                      storeSettings.serviceChargePercentage;

                  final int subtotal = state.totalAmount;
                  final int tax = _calculateCharge(subtotal, taxRate);
                  final int serviceCharge = _calculateCharge(
                    subtotal,
                    serviceChargeRate,
                  );
                  final int total = subtotal + tax + serviceCharge;

                  return Container(
                    color: AppPallete.surface,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppPallete.textPrimary),
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
                                    UpdateCartItemQuantityEvent(
                                      item.id,
                                      newQuantity,
                                    ),
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
                        SummaryRow(
                          label: 'Tax (${_formatPercentage(taxRate)}%)',
                          value: tax,
                        ),
                        const SizedBox(height: 6),
                        SummaryRow(
                          label:
                              'Service (${_formatPercentage(serviceChargeRate)}%)',
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
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: () => _createOrder(
                                      context,
                                      'QRIS',
                                      total,
                                      taxPercentage: taxRate,
                                      serviceChargePercentage:
                                          serviceChargeRate,
                                    ),
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
                                    onPressed: () => _showCashPaymentDialog(
                                      context,
                                      total,
                                      taxPercentage: taxRate,
                                      serviceChargePercentage:
                                          serviceChargeRate,
                                    ),
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
            );
          },
        ),
      ),
    );
  }

  void _showCashPaymentDialog(
    BuildContext context,
    int total, {
    required double taxPercentage,
    required double serviceChargePercentage,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CashPaymentDialog(
          total: total,
          onConfirmPayment: (int amountPaid) {
            _createOrder(
              context,
              'CASH',
              total,
              amountPaid: amountPaid,
              taxPercentage: taxPercentage,
              serviceChargePercentage: serviceChargePercentage,
            );
          },
        );
      },
    );
  }

  void _createOrder(
    BuildContext context,
    String method,
    int total, {
    int? amountPaid,
    required double taxPercentage,
    required double serviceChargePercentage,
  }) {
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
        menuName: cartItem.name,
        quantity: cartItem.quantity,
        unitPrice: (cartItem.basePrice + _modifiersUnitPrice(cartItem))
            .toInt(), // Include modifier price
        notes: null, // Could be added later for special instructions
        modifierSnapshot: modifierSnapshot.isNotEmpty ? modifierSnapshot : null,
      );
    }).toList();

    // Calculate amounts
    final int subtotal = cartState.totalAmount;

    // Use provided amountPaid or default to total for QRIS
    final int finalAmountPaid = amountPaid ?? total;

    orderBloc.add(
      CreateOrderEvent(
        orderNumber: orderNumber,
        tableNumber: tableBloc.state.selectedTableNumber,
        cashierId: userState.user.id,
        subtotal: subtotal,
        tax: taxPercentage,
        serviceCharge: serviceChargePercentage,
        total: total,
        method: method,
        amountPaid: finalAmountPaid,
        items: orderItems,
      ),
    );
  }

  int _calculateCharge(int subtotal, double percentage) {
    return (subtotal * percentage / 100).round();
  }

  String _formatPercentage(double percentage) {
    if (percentage == percentage.truncateToDouble()) {
      return percentage.toStringAsFixed(0);
    }

    return percentage
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
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

class CashPaymentDialog extends StatefulWidget {
  final int total;
  final Function(int) onConfirmPayment;

  const CashPaymentDialog({
    super.key,
    required this.total,
    required this.onConfirmPayment,
  });

  @override
  State<CashPaymentDialog> createState() => _CashPaymentDialogState();
}

class _CashPaymentDialogState extends State<CashPaymentDialog> {
  late final TextEditingController amountController;
  bool isFormatting = false;
  int change = 0;
  String formattedAmount = '';

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isValidPayment = change >= 0 && amountController.text.isNotEmpty;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460),
        decoration: BoxDecoration(
          color: AppPallete.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x22000000),
              blurRadius: 26,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                gradient: const LinearGradient(
                  colors: [AppPallete.primary, AppPallete.secondary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_rounded,
                    color: AppPallete.onPrimary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Cash Payment',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppPallete.onPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppPallete.onPrimary,
                    ),
                    splashRadius: 18,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppPallete.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Bill',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppPallete.textPrimary),
                        ),
                        Text(
                          'Rp ${_formatCurrency(widget.total)}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppPallete.primary,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppPallete.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount Paid',
                      prefixText: 'Rp ',
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppPallete.divider),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppPallete.primary,
                          width: 1.6,
                        ),
                      ),
                      labelStyle: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppPallete.textPrimary),
                    ),
                    onChanged: (value) {
                      if (isFormatting) return;

                      final amount = _parseAmount(value);
                      final formatted = amount > 0
                          ? _formatCurrency(amount)
                          : '';

                      setState(() {
                        change = amount - widget.total;
                        formattedAmount = formatted;
                      });

                      if (formatted != value) {
                        isFormatting = true;
                        amountController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(
                            offset: formatted.length,
                          ),
                        );
                        isFormatting = false;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: change >= 0
                          ? AppPallete.success.withValues(alpha: 0.12)
                          : AppPallete.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          change >= 0
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          color: change >= 0
                              ? AppPallete.success
                              : AppPallete.error,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            change >= 0
                                ? 'Change: Rp ${_formatCurrency(change)}'
                                : 'Insufficient: Rp ${_formatCurrency(change.abs())} short',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: change >= 0
                                      ? AppPallete.success
                                      : AppPallete.error,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppPallete.divider),
                            foregroundColor: AppPallete.textPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isValidPayment
                              ? () {
                                  final amount = _parseAmount(
                                    amountController.text,
                                  );
                                  Navigator.of(context).pop();
                                  widget.onConfirmPayment(amount);
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPallete.secondary,
                            foregroundColor: AppPallete.onPrimary,
                            disabledBackgroundColor: AppPallete.secondary
                                .withValues(alpha: 0.35),
                            disabledForegroundColor: AppPallete.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Confirm Payment'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _parseAmount(String value) {
    final cleanValue = value.replaceAll('.', '').replaceAll('Rp ', '').trim();
    return int.tryParse(cleanValue) ?? 0;
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
