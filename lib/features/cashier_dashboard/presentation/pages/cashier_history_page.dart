import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class CashierHistoryPage extends StatelessWidget {
  const CashierHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Center(
        child: Text(
          'Transaction history will appear here.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppPallete.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
