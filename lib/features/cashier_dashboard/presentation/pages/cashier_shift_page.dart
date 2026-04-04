import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class CashierShiftPage extends StatelessWidget {
  const CashierShiftPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shift')),
      body: Center(
        child: Text(
          'Shift information will appear here.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppPallete.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
