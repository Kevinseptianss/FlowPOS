import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/list_menu_section.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/list_order_section.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/table_section.dart';
import 'package:flutter/material.dart';

class CashierIpadPage extends StatelessWidget {
  const CashierIpadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'FlowPOS',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppPallete.onPrimary),
            ),
            Text(
              'Cashier: Jason',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppPallete.onPrimary),
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          Expanded(flex: 1, child: TableSection()),
          Expanded(flex: 2, child: ListMenuSection()),
          Expanded(flex: 1, child: ListOrderSection()),
        ],
      ),
    );
  }
}
