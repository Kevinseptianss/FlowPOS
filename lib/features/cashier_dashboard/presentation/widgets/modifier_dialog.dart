import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/cashier_dashboard/domain/entities/selected_modifier.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/modifier_option_row.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/qty_button.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item_variant.dart';
import 'package:flutter/material.dart';

class ModifierDialog extends StatefulWidget {
  final String menuId;
  final String itemName;
  final int price;
  final List<MenuItemVariant> variants;

  const ModifierDialog({
    super.key,
    required this.menuId,
    required this.itemName,
    required this.price,
    required this.variants,
  });

  @override
  State<ModifierDialog> createState() => _ModifierDialogState();
}

class _ModifierDialogState extends State<ModifierDialog> {
  int quantity = 1;
  final Map<String, SelectedModifier?> selectedModifierByGroup = {};

  @override
  void initState() {
    super.initState();
  }

  int _calculateModifiersPrice() {
    int total = 0;
    for (var group in selectedModifierByGroup.values) {
      if (group != null) {
        // Find the variant to get its price
        final variant = widget.variants.firstWhere((v) => v.id == group.id);
        total += variant.price;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final groupedOptions = <String, List<MenuItemVariant>>{};
    for (final variant in widget.variants) {
      groupedOptions
          .putIfAbsent(variant.optionName, () => [])
          .add(variant);
    }

    final modifiersTotal = _calculateModifiersPrice();
    final totalPrice = (widget.price + modifiersTotal) * quantity;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppPallete.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.itemName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppPallete.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Harga Dasar: Rp ${widget.price}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppPallete.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Kuantitas',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppPallete.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                        const SizedBox(width: 20),
                        Text(
                          '$quantity',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: AppPallete.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 20),
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
                    const SizedBox(height: 24),
                    if (groupedOptions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Text(
                          'Note: Produk ini tidak memiliki varian tambahan.',
                          style: TextStyle(color: AppPallete.textSecondary, fontStyle: FontStyle.italic),
                        ),
                      )
                    else
                      ...groupedOptions.entries.map((entry) {
                        final groupName = entry.key;
                        final options = entry.value;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              groupName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppPallete.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...options.map((variant) {
                              final isSelected =
                                  selectedModifierByGroup[groupName]?.id ==
                                      variant.id;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: ModifierOptionRow(
                                  label: variant.variantName,
                                  additionalPrice: variant.price,
                                  isSelected: isSelected,
                                  onTap: () {
                                    setState(() {
                                      // If already selected, deselect it
                                      if (isSelected) {
                                        selectedModifierByGroup[groupName] = null;
                                      } else {
                                        selectedModifierByGroup[groupName] =
                                            SelectedModifier(
                                          id: variant.id,
                                          name: variant.variantName,
                                        );
                                      }
                                    });
                                  },
                                ),
                              );
                            }),
                            const SizedBox(height: 20),
                          ],
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),
            const Divider(height: 32),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Harga',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppPallete.textPrimary,
                      ),
                    ),
                    Text(
                      'Rp $totalPrice',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppPallete.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppPallete.primary),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context, {
                          'totalPrice': totalPrice,
                          'selectedModifiers': Map<String, SelectedModifier?>.from(
                            selectedModifierByGroup,
                          ),
                          'quantity': quantity,
                        }),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPallete.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Tambah ke Keranjang'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
