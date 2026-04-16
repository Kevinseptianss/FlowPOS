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
      height: 72,
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 25,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / 5;
          
          return Stack(
            children: [
              // Sliding Highlight background
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutQuart,
                left: currentIndex * itemWidth + (itemWidth * 0.1),
                top: 10,
                child: Container(
                  width: itemWidth * 0.8,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppPallete.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),
              Row(
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
            ],
          );
        },
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

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 400),
                scale: isSelected ? 1.15 : 1.0,
                child: Icon(
                  icon,
                  color: isSelected ? activeColor : inactiveColor,
                  size: 24,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? activeColor : inactiveColor,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
