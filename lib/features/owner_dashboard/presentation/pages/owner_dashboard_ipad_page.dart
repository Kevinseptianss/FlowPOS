import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/datetime_formatter.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/analytic_section.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/manage_menu_section.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/order_section.dart';
import 'package:flutter/material.dart';

class OwnerDashboardIpadPage extends StatelessWidget {
  const OwnerDashboardIpadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'FlowPOS',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppPallete.onPrimary),
                ),
                const SizedBox(width: 10),
                const SizedBox(
                  height: 24,
                  width: 2,
                  child: VerticalDivider(
                    color: AppPallete.divider,
                    thickness: 2,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Owner Dashboard',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppPallete.onPrimary),
                ),
              ],
            ),
            Text(
              DatetimeFormatter.formatDateYear(),
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppPallete.textSecondary),
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: AppPallete.background),
              child: const Column(
                children: [
                  AnalyticSection(),
                  SizedBox(height: 24),
                  Expanded(child: OrderSection()),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              height: double.infinity,
              decoration: BoxDecoration(
                color: AppPallete.surface,
                border: Border(
                  left: BorderSide(
                    color: AppPallete.textPrimary.withAlpha(127),
                  ),
                ),
              ),
              child: ManageMenuSection(),
            ),
          ),
        ],
      ),
    );
  }
}
