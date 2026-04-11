import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class OwnerProductsPage extends StatelessWidget {
  const OwnerProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppPallete.background,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manajemen Produk',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppPallete.primary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Kelola menu dan produk Anda di sini.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppPallete.textSecondary,
                ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: AppPallete.primary.withAlpha(50),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fitur Produk sedang dikembangkan',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppPallete.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
