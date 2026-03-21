import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/menu_item_card.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/modifier_dialog.dart';
import 'package:flow_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ListMenuSection extends StatefulWidget {
  const ListMenuSection({super.key});

  @override
  State<ListMenuSection> createState() => _ListMenuSectionState();
}

class _ListMenuSectionState extends State<ListMenuSection> {
  static const List<Map<String, dynamic>> _menuItems = [
    {'name': 'Iced Americano', 'price': 15000, 'category': 'Beverage'},
    {'name': 'Cappuccino', 'price': 22000, 'category': 'Beverage'},
    {'name': 'Chicken Sandwich', 'price': 28000, 'category': 'Food'},
    {'name': 'Chocolate Croissant', 'price': 18000, 'category': 'Pastry'},
    {'name': 'Matcha Latte', 'price': 25000, 'category': 'Beverage'},
    {'name': 'French Fries', 'price': 20000, 'category': 'Snack'},
    {'name': 'Blueberry Muffin', 'price': 20000, 'category': 'Pastry'},
    {'name': 'Grilled Cheese Sandwich', 'price': 30000, 'category': 'Food'},
  ];

  static const List<Map<String, dynamic>> _modifierGroups = [
    {
      'groupName': 'Ice',
      'options': [
        {'name': 'Less Ice', 'additionalPrice': 0},
        {'name': 'Normal Ice', 'additionalPrice': 0},
      ],
    },
    {
      'groupName': 'Add-ons',
      'options': [
        {'name': 'Extra Shot', 'additionalPrice': 5000},
        {'name': 'Less Sugar', 'additionalPrice': 0},
        {'name': 'No Dairy', 'additionalPrice': 3000},
      ],
    },
  ];

  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(GetAllCategoriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _selectedCategory == 'all'
        ? _menuItems
        : _menuItems
              .where((item) => item['category'] == _selectedCategory)
              .toList();

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
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.9,
              ),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) {
                final item = filteredItems[index];

                return MenuItemCard(
                  name: item['name'] as String,
                  price: item['price'] as int,
                  onAdd: () => showDialog(
                    context: context,
                    builder: (context) => ModifierDialog(
                      itemName: item['name'],
                      price: item['price'],
                      modifierGroups: _modifierGroups,
                    ),
                  ),
                );
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
