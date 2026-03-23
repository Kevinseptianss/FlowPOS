import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/modifier_option_row.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/qty_button.dart';
import 'package:flow_pos/features/modifier_option/domain/entities/modifier_option.dart';
import 'package:flow_pos/features/modifier_option/presentation/bloc/modifier_option_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ModifierDialog extends StatefulWidget {
  final String menuId;
  final String itemName;
  final int price;

  const ModifierDialog({
    super.key,
    required this.menuId,
    required this.itemName,
    required this.price,
  });

  @override
  State<ModifierDialog> createState() => _ModifierDialogState();
}

class _ModifierDialogState extends State<ModifierDialog> {
  int quantity = 1;
  static const double _fixedSectionsHeight = 250;
  final Map<String, String?> selectedModifierByGroup = {};

  int _selectedModifiersPrice(List<ModifierOption> options) {
    final selectedOptionIds = selectedModifierByGroup.values
        .whereType<String>()
        .toSet();

    return options
        .where((option) => selectedOptionIds.contains(option.id))
        .fold(0, (sum, option) => sum + option.additionalPrice);
  }

  @override
  void initState() {
    super.initState();
    context.read<ModifierOptionBloc>().add(
      GetAllModifierOptionsEvent(menuId: widget.menuId),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: BlocBuilder<ModifierOptionBloc, ModifierOptionState>(
          builder: (context, state) {
            if (state is ModifierOptionInitial ||
                state is ModifierOptionLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ModifierOptionFailure) {
              return Center(child: Text('Error: ${state.message}'));
            }

            if (state is ModifierOptionLoaded) {
              final groupedOptions = <String, List<ModifierOption>>{};
              final groupNames = <String, String>{};

              for (final option in state.modifierOptions) {
                groupedOptions
                    .putIfAbsent(option.modifierGroupId, () => [])
                    .add(option);
                groupNames[option.modifierGroupId] = option.modifierGroupName;
              }

              final modifiersTotal = _selectedModifiersPrice(
                state.modifierOptions,
              );
              final totalPrice = (widget.price + modifiersTotal) * quantity;
              final maxListHeight =
                  MediaQuery.of(context).size.height * 0.82 -
                  _fixedSectionsHeight;

              return Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.itemName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppPallete.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${widget.price}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppPallete.primary,
                        ),
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: AppPallete.textPrimary),
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
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: maxListHeight > 120 ? maxListHeight : 120,
                        ),
                        child: SingleChildScrollView(
                          child: groupedOptions.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    'No modifier options available.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppPallete.textPrimary,
                                        ),
                                  ),
                                )
                              : Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: groupedOptions.entries.expand((
                                    entry,
                                  ) {
                                    final groupId = entry.key;
                                    final groupName =
                                        groupNames[groupId] ?? 'Modifier';
                                    final options = entry.value;

                                    return [
                                      Text(
                                        groupName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              color: AppPallete.textPrimary,
                                            ),
                                      ),
                                      const SizedBox(height: 8),
                                      ...options.map((modifier) {
                                        final isSelected =
                                            selectedModifierByGroup[groupId] ==
                                            modifier.id;

                                        return ModifierOptionRow(
                                          label: modifier.name,
                                          additionalPrice:
                                              modifier.additionalPrice,
                                          isSelected: isSelected,
                                          onTap: () {
                                            setState(() {
                                              selectedModifierByGroup[groupId] =
                                                  modifier.id;
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
                    ],
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: AppPallete.surface,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(16),
                          bottomRight: Radius.circular(16),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Divider(color: AppPallete.divider),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Price',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(color: AppPallete.textPrimary),
                              ),
                              Text(
                                'Rp $totalPrice',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
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
                                onPressed: () => Navigator.pop(context, {
                                  'totalPrice': totalPrice,
                                  'selectedModifiers': selectedModifierByGroup,
                                  'quantity': quantity,
                                }),
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
                  ),
                ],
              );
            }

            return const SizedBox();
          },
        ),
      ),
    );
  }
}
