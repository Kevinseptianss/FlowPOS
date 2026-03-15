import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

import 'order_card.dart';

class OrderSection extends StatelessWidget {
  const OrderSection({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data
    final List<Map<String, dynamic>> orders = [
      {
        'orderId': 'ORD-001',
        'paymentType': 'QRIS',
        'datetime': '2026-03-14 10:30',
        'totalItems': 5,
        'totalPayment': '150.000',
      },
      {
        'orderId': 'ORD-002',
        'paymentType': 'Cash',
        'datetime': '2026-03-14 11:15',
        'totalItems': 3,
        'totalPayment': '75.000',
      },
      {
        'orderId': 'ORD-003',
        'paymentType': 'QRIS',
        'datetime': '2026-03-14 12:00',
        'totalItems': 7,
        'totalPayment': '200.000',
      },
      {
        'orderId': 'ORD-004',
        'paymentType': 'Cash',
        'datetime': '2026-03-14 12:45',
        'totalItems': 2,
        'totalPayment': '50.000',
      },
      {
        'orderId': 'ORD-005',
        'paymentType': 'QRIS',
        'datetime': '2026-03-14 13:30',
        'totalItems': 4,
        'totalPayment': '120.000',
      },
    ];

    // final orders = [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Recent Orders',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: orders.isEmpty
              ? Center(
                  child: Text(
                    "Order is empty",
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppPallete.primary),
                  ),
                )
              : ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return OrderCard(
                      orderId: order['orderId'] as String,
                      paymentType: order['paymentType'] as String,
                      datetime: order['datetime'] as String,
                      totalItems: order['totalItems'] as int,
                      totalPayment: order['totalPayment'] as String,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
