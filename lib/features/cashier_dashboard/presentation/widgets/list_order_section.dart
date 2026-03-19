import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/qty_button.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/summary_row.dart';
import 'package:flutter/material.dart';

class ListOrderSection extends StatelessWidget {
  const ListOrderSection({super.key});

  static const List<Map<String, dynamic>> _orderItems = [
    {'name': 'Iced Americano', 'qty': 2, 'price': 15000},
    {'name': 'Chicken Sandwich', 'qty': 1, 'price': 28000},
    {'name': 'Chocolate Croissant', 'qty': 1, 'price': 18000},
    {'name': 'Matcha Latte', 'qty': 3, 'price': 25000},
    {'name': 'French Fries', 'qty': 2, 'price': 20000},
  ];

  @override
  Widget build(BuildContext context) {
    const int taxRate = 10;
    final int subtotal = _orderItems.fold(
      0,
      (sum, item) => sum + (item['qty'] as int) * (item['price'] as int),
    );
    final int tax = (subtotal * taxRate) ~/ 100;
    final int total = subtotal + tax;

    return Container(
      color: AppPallete.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppPallete.textPrimary),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _orderItems.length,
              itemBuilder: (context, index) {
                final item = _orderItems[index];

                return _OrderItemTile(
                  name: item['name'] as String,
                  qty: item['qty'] as int,
                  price: item['price'] as int,
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
          const SizedBox(height: 8),
          const Divider(color: AppPallete.divider),
          const SizedBox(height: 8),
          SummaryRow(label: 'Total', value: total, isTotal: true),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPallete.primary,
                    foregroundColor: AppPallete.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
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
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPallete.secondary,
                    foregroundColor: AppPallete.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('CASH'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final String name;
  final int qty;
  final int price;

  const _OrderItemTile({
    required this.name,
    required this.qty,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    final int subtotal = qty * price;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppPallete.divider)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPallete.textPrimary,
                      ),
                      softWrap: true,
                      maxLines: null,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp $price',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppPallete.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    QtyButton(icon: Icons.remove, onTap: () {}),
                    const SizedBox(width: 8),
                    Text(
                      '$qty',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPallete.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    QtyButton(icon: Icons.add, onTap: () {}),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Rp $subtotal',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPallete.primary),
            ),
          ),
        ],
      ),
    );
  }
}
