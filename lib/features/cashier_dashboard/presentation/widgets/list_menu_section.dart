import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/cashier_dashboard/domain/entities/selected_modifier.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/cart_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/menu_item_card.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/modifier_dialog.dart';
import 'package:flow_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flow_pos/features/menu_item/presentation/bloc/menu_item_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListMenuSection extends StatefulWidget {
  const ListMenuSection({super.key});

  @override
  State<ListMenuSection> createState() => _ListMenuSectionState();
}

class _ListMenuSectionState extends State<ListMenuSection> {
  String _selectedCategory = 'all';
  late final CategoryBloc _categoryBloc;
  late final MenuItemBloc _menuItemBloc;

  @override
  void initState() {
    super.initState();
    _categoryBloc = context.read<CategoryBloc>();
    _menuItemBloc = context.read<MenuItemBloc>();

    _categoryBloc.add(GetAllCategoriesEvent());
    _menuItemBloc.add(GetEnabledMenuItemsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppPallete.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Menu',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppPallete.textPrimary),
          ),
          const SizedBox(height: 12),
          BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, state) {
              if (state is CategoryLoading) {
                return const Text('Loading categories...');
              } else if (state is CategoryFailure) {
                return Text('Error: ${state.message}');
              } else if (state is CategoryLoaded) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.categories
                      .map(
                        (category) => _CategoryBadge(
                          label: category.name,
                          isSelected: _selectedCategory == category.id,
                          onTap: () {
                            setState(() {
                              _selectedCategory = category.id;
                            });
                          },
                        ),
                      )
                      .toList(),
                );
              } else {
                return const SizedBox();
              }
            },
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BlocConsumer<MenuItemBloc, MenuItemState>(
              listener: (context, state) {
                if (state is MenuItemFailure) {
                  showSnackbar(context, state.message);
                }
              },
              builder: (context, state) {
                if (state is MenuItemLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is MenuItemLoaded) {
                  final filteredItems = _selectedCategory == 'all'
                      ? state.menuItems
                      : state.menuItems
                            .where(
                              (item) => item.category.id == _selectedCategory,
                            )
                            .toList();

                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<MenuItemBloc>().add(
                        GetEnabledMenuItemsEvent(),
                      );

                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];

                        return MenuItemCard(
                          name: item.name,
                          price: item.price,
                          onQuickAdd: () {
                            context.read<CartBloc>().add(
                              AddToCartEvent(
                                menuItemId: item.id,
                                name: item.name,
                                basePrice: item.price,
                                costPrice: item.basePrice,
                                quantity: 1,
                                selectedModifiers: const {},
                                totalPrice: item.price,
                                notes: '',
                              ),
                            );
                          },
                          onShowDetail: () async {
                            final cartBloc = context.read<CartBloc>();
                            final result =
                                await showModalBottomSheet<
                                  Map<String, dynamic>
                                >(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) => ModifierDialog(
                                    menuId: item.id,
                                    itemName: item.name,
                                    price: item.price,
                                    basePrice: item.basePrice,
                                    variants: item.variants,
                                  ),
                                );
 
                            if (result != null) {
                              cartBloc.add(
                                AddToCartEvent(
                                  menuItemId: item.id,
                                  name: item.name,
                                  basePrice: item.price,
                                  costPrice: (result['totalCost'] as num).toInt(),
                                  quantity: (result['quantity'] as num).toInt(),
                                  selectedModifiers:
                                      result['selectedModifiers']
                                          as Map<String, SelectedModifier?>,
                                  totalPrice: (result['totalPrice'] as num)
                                      .toInt(),
                                  variantId: result['variantId'] as String?,
                                  notes: result['notes'] as String?,
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  );
                } else {
                  return const Center(child: Text("No Menu Items Available"));
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryBadge({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppPallete.primary : AppPallete.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppPallete.primary : AppPallete.divider,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected ? AppPallete.onPrimary : AppPallete.textPrimary,
          ),
        ),
      ),
    );
  }
}
