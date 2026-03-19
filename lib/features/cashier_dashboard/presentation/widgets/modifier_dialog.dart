import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/modifier_option_row.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/qty_button.dart';
import 'package:flutter/material.dart';

class ModifierDialog extends StatefulWidget {
  final String itemName;
  final int price;
  final List<Map<String, dynamic>> modifierGroups;

  const ModifierDialog({
    super.key,
    required this.itemName,
    required this.price,
    required this.modifierGroups,
  });

  @override
  State<ModifierDialog> createState() => _ModifierDialogState();
}

class _ModifierDialogState extends State<ModifierDialog> {
  late final String itemName;
  late final int price;
  late final List<Map<String, dynamic>> modifierGroups;
  int quantity = 1;
  final Map<String, String?> selectedModifierByGroup = {};

  int _selectedModifiersPrice() {
    int total = 0;

    for (final group in modifierGroups) {
      final groupName = group['groupName'] as String;
      final selectedModifierName = selectedModifierByGroup[groupName];

      if (selectedModifierName == null) {
        continue;
      }

      final options = group['options'] as List<Map<String, dynamic>>;
      final selectedOption = options.cast<Map<String, dynamic>>().firstWhere(
        (option) => option['name'] == selectedModifierName,
        orElse: () => <String, dynamic>{},
      );

      if (selectedOption.isNotEmpty) {
        total += selectedOption['additionalPrice'] as int;
      }
    }

    return total;
  }

  @override
  void initState() {
    super.initState();
    itemName = widget.itemName;
    price = widget.price;
    modifierGroups = widget.modifierGroups;
  }

  @override
  Widget build(BuildContext context) {
    final modifiersTotal = _selectedModifiersPrice();
    final totalPrice = (price + modifiersTotal) * quantity;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPallete.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              itemName,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: AppPallete.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'Rp $price',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPallete.primary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                QtyButton(
                  icon: Icons.remove,
                  onTap: () {
                    setState(() {
                      if (quantity > 1) {
                        quantity -= 1;
                      }
                    });
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  '$quantity',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppPallete.textPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                QtyButton(
                  icon: Icons.add,
                  onTap: () {
                    setState(() {
                      quantity += 1;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: modifierGroups.expand((group) {
                    final groupName = group['groupName'] as String;
                    final options =
                        group['options'] as List<Map<String, dynamic>>;
                    return [
                      Text(
                        groupName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppPallete.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...options.map((modifier) {
                        final modifierName = modifier['name'] as String;
                        final additionalPrice =
                            modifier['additionalPrice'] as int;
                        final isSelected =
                            selectedModifierByGroup[groupName] == modifierName;

                        return ModifierOptionRow(
                          label: modifierName,
                          additionalPrice: additionalPrice,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              selectedModifierByGroup[groupName] = modifierName;
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 16),
                    ];
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: AppPallete.divider),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Price',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppPallete.textPrimary,
                  ),
                ),
                Text(
                  'Rp $totalPrice',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppPallete.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: AppPallete.primary,
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPallete.primary,
                    foregroundColor: AppPallete.onPrimary,
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
