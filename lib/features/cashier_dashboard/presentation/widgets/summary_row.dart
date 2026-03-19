import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class SummaryRow extends StatelessWidget {
  final String label;
  final int value;
  final bool isTotal;

  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = isTotal
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textStyle?.copyWith(color: AppPallete.textPrimary)),
        Text(
          'Rp $value',
          style: textStyle?.copyWith(color: AppPallete.textPrimary),
        ),
      ],
    );
  }
}
