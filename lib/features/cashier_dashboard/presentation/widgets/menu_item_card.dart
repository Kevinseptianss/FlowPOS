import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flutter/material.dart';

class MenuItemCard extends StatelessWidget {
  final String name;
  final int price;
  final VoidCallback onAdd;

  const MenuItemCard({
    super.key,
    required this.name,
    required this.price,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPallete.divider),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/default-food.jpg',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(
                    color: AppPallete.textPrimary,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                price == 0 ? 'Gratis' : formatRupiah(price),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(
                    color: AppPallete.primary,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 28),
            ],
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppPallete.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: AppPallete.onPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
