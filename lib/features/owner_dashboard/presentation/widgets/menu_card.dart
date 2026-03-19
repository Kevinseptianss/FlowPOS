import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class MenuCard extends StatefulWidget {
  final String title;
  final int price;
  final String category;
  final bool enabled;
  final Image image;

  const MenuCard({
    super.key,
    required this.title,
    required this.price,
    required this.category,
    required this.enabled,
    required this.image,
  });

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  late String _title;
  late int _price;
  late String _category;
  late bool _enabled;
  late Image _image;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _price = widget.price;
    _category = widget.category;
    _enabled = widget.enabled;
    _image = widget.image;
  }

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
                child: _image,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppPallete.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Rp ${_price.toString()}",
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
                      _category,
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
                value: _enabled,
                onChanged: (value) {
                  setState(() {
                    _enabled = value;
                  });
                },
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
