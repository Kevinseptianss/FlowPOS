import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flutter/material.dart';

class MenuCard extends StatelessWidget {
  final String title;
  final int price;
  final String category;
  final bool enabled;
  final Image image;
  final ValueChanged<bool>? onEnabledChanged;

  const MenuCard({
    super.key,
    required this.title,
    required this.price,
    required this.category,
    required this.enabled,
    required this.image,
    this.onEnabledChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppPallete.background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 56,
                height: 56,
                color: AppPallete.surface,
                alignment: Alignment.center,
                child: image,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppPallete.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatRupiah(price),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppPallete.primary),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppPallete.surface,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppPallete.divider),
                    ),
                    child: Text(
                      category,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppPallete.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Transform.scale(
              scale: 0.7,
              child: Switch(
                value: enabled,
                onChanged: onEnabledChanged,
                activeThumbColor: AppPallete.success,
                inactiveThumbColor: AppPallete.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
