import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class AnalyticCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const AnalyticCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: AppPallete.surface,
      child: Container(
        height: 80,
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Row(
              children: [
                Icon(icon, color: AppPallete.primary),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.black),
                ),
              ],
            ),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
