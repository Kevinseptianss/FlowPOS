import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const QtyButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppPallete.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppPallete.divider),
        ),
        child: Icon(icon, size: 16, color: AppPallete.textPrimary),
      ),
    );
  }
}
