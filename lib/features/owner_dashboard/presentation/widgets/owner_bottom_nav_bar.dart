import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class OwnerBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onIndexChanged;

  const OwnerBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPallete.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _BottomNavItem(
                icon: Icons.grid_view_rounded,
                label: 'Utama',
                isSelected: currentIndex == 0,
                onTap: () => onIndexChanged(0),
              ),
              _BottomNavItem(
                icon: Icons.inventory_2_outlined,
                label: 'Produk',
                isSelected: currentIndex == 1,
                onTap: () => onIndexChanged(1),
              ),
              _BottomNavItem(
                icon: Icons.inventory_outlined,
                label: 'Stok',
                isSelected: currentIndex == 2,
                onTap: () => onIndexChanged(2),
              ),
              _BottomNavItem(
                icon: Icons.storefront_outlined,
                label: 'Toko',
                isSelected: currentIndex == 3,
                onTap: () => onIndexChanged(3),
              ),
              _BottomNavItem(
                icon: Icons.settings_outlined,
                label: 'Atur',
                isSelected: currentIndex == 4,
                onTap: () => onIndexChanged(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor = AppPallete.textSecondary;
    final activeColor = AppPallete.primary;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color:
                  isSelected ? activeColor.withAlpha(40) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isSelected ? activeColor : inactiveColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
          ),
        ],
      ),
    );
  }
}
