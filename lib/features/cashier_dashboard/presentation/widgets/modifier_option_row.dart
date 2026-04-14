import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flutter/material.dart';

class ModifierOptionRow extends StatelessWidget {
  final String label;
  final int additionalPrice;
  final bool isSelected;
  final VoidCallback onTap;

  const ModifierOptionRow({
    super.key,
    required this.label,
    required this.additionalPrice,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppPallete.primary.withValues(alpha: 0.08)
              : AppPallete.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppPallete.primary : AppPallete.divider,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppPallete.textPrimary),
              ),
            ),
            Text(
              additionalPrice == 0 ? '+ Rp 0' : '+ ${formatRupiah(additionalPrice)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isSelected ? AppPallete.primary : AppPallete.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
