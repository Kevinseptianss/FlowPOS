import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/table_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/cart_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/domain/entities/cart.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class TableSection extends StatelessWidget {
  const TableSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        border: Border(
          right: BorderSide(color: AppPallete.textPrimary.withAlpha(127)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Table Map',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              _LegendItem(),
            ],
          ),
          const SizedBox(height: 12),
          // Selected Table Detail Card
          BlocBuilder<TableBloc, TableState>(
            builder: (context, tableState) {
              return BlocBuilder<OrderBloc, OrderState>(
                builder: (context, orderState) {
                  final tableNumber = tableState.selectedTableNumber;
                  final isOccupied = tableState.occupiedTableNumbers.contains(
                    tableNumber,
                  );
                  final guestName =
                      tableState.occupiedTableNames[tableNumber] ?? 'Empty';

                  int? totalAmount;
                  int? itemCount;

                  if (orderState is OrdersLoaded && isOccupied) {
                    final order = orderState.orders.firstWhere(
                      (o) =>
                          o.tableNumber == tableNumber && o.status == 'UNPAID',
                      orElse: () => orderState.orders.first, // fallback
                    );
                    if (order.tableNumber == tableNumber) {
                      totalAmount = order.total;
                      itemCount = order.items.where((i) => !i.isDeleted).length;
                    }
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isOccupied
                          ? Colors.orange.shade50
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: (isOccupied ? Colors.orange : Colors.blue)
                            .withAlpha(100),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isOccupied ? Colors.orange : Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            'T$tableNumber',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isOccupied
                                  ? 'Occupied - $guestName'
                                  : 'Table Available',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isOccupied
                                    ? Colors.orange.shade900
                                    : Colors.blue.shade900,
                              ),
                            ),
                            if (isOccupied && totalAmount != null)
                              Text(
                                '$itemCount items • total: Rp ${totalAmount.toString()}', // Simple format for now
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade800,
                                ),
                              )
                            else
                              const Text(
                                'Ready for new customer',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blueGrey,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          Expanded(
            child: SingleChildScrollView(
              child: BlocBuilder<TableBloc, TableState>(
                builder: (context, state) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(24, (index) {
                      // Increased to 24 tables
                      final tableNumber = index + 1;
                      final isSelected =
                          state.selectedTableNumber == tableNumber;
                      final isOccupied = state.occupiedTableNumbers.contains(
                        tableNumber,
                      );
                      final tableName = state.occupiedTableNames[tableNumber];

                      Color baseColor = AppPallete.background;
                      Color borderColor = AppPallete.divider;
                      Color contentColor = AppPallete.textPrimary;

                      if (isSelected) {
                        baseColor = AppPallete.primary;
                        borderColor = AppPallete.primary;
                        contentColor = Colors.white;
                      } else if (isOccupied) {
                        baseColor = Colors.orange.shade400;
                        borderColor = Colors.orange.shade600;
                        contentColor = Colors.white;
                      } else {
                        // Available
                        baseColor = Colors.green.shade50;
                        borderColor = Colors.green.shade200;
                        contentColor = Colors.green.shade800;
                      }

                      return InkWell(
                        onTap: () {
                          context.read<TableBloc>().add(
                            SelectTableEvent(tableNumber),
                          );

                          // SYNC CART manually for iPad/Tab when switching tables
                          final orderState = context.read<OrderBloc>().state;
                          if (orderState is OrdersLoaded) {
                            final matchingOrders = orderState.orders
                                .where(
                                  (o) =>
                                      o.tableNumber == tableNumber &&
                                      o.status.trim().toUpperCase() == 'UNPAID',
                                )
                                .toList();

                            if (matchingOrders.isNotEmpty) {
                              final cartItems = matchingOrders
                                  .expand(
                                    (o) => o.items.where((i) => !i.isDeleted),
                                  )
                                  .map(
                                    (item) => Cart(
                                      id: const Uuid().v4(),
                                      menuItemId: item.menuItemId,
                                      name: item.menuName,
                                      basePrice: item.unitPrice,
                                      costPrice: item.costPrice,
                                      quantity: item.quantity,
                                      selectedModifiers: const {},
                                      totalPrice:
                                          item.unitPrice * item.quantity,
                                      variantId: item.variantId,
                                      notes: item.notes,
                                    ),
                                  )
                                  .toList();
                              context.read<CartBloc>().add(
                                ReplaceCartItemsEvent(cartItems),
                              );
                            } else {
                              context.read<CartBloc>().add(
                                const ClearCartEvent(),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 52, // Slightly smaller to fix spacing
                          height: 52,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: baseColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: borderColor, width: 1.5),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'T$tableNumber',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: contentColor,
                                ),
                              ),
                              if (isOccupied)
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                  ),
                                  child: Text(
                                    tableName ?? 'G',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _dot(Colors.green.shade400, 'Free'),
        const SizedBox(width: 8),
        _dot(Colors.orange.shade400, 'Busy'),
      ],
    );
  }

  Widget _dot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppPallete.textSecondary),
        ),
      ],
    );
  }
}
