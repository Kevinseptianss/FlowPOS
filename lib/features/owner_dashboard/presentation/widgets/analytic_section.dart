import 'package:flutter/material.dart';

import 'analytic_card.dart';
import 'income_card.dart';

class AnalyticSection extends StatelessWidget {
  const AnalyticSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AnalyticCard(
                icon: Icons.trending_up,
                title: 'Revenue',
                value: '1.234',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnalyticCard(
                icon: Icons.shopping_cart,
                title: 'Orders',
                value: '56',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnalyticCard(
                icon: Icons.calculate,
                title: 'Avg/Orders',
                value: '22.05',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnalyticCard(
                icon: Icons.inventory,
                title: 'Active Items',
                value: '12',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const IncomeCard(),
      ],
    );
  }
}
