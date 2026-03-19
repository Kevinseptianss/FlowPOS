import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class OrderCard extends StatelessWidget {
  final String orderId;
  final String paymentType;
  final String datetime;
  final int totalItems;
  final String totalPayment;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.paymentType,
    required this.datetime,
    required this.totalItems,
    required this.totalPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppPallete.surface,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  orderId,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppPallete.primary),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: paymentType == 'QRIS'
                        ? AppPallete.primary
                        : AppPallete.secondary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    paymentType,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppPallete.onPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$datetime - $totalItems items',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppPallete.primary),
                ),
                Text(
                  totalPayment,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppPallete.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
