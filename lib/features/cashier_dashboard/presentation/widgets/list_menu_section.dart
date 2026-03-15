import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class ListMenuSection extends StatefulWidget {
  const ListMenuSection({super.key});

  @override
  State<ListMenuSection> createState() => _ListMenuSectionState();
}

class _ListMenuSectionState extends State<ListMenuSection> {
  static const List<String> _categories = [
    'All',
    'Beverage',
    'Food',
    'Pastry',
    'Snack',
  ];

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

  String _selectedCategory = 'All';

  void _showModifierDialog(BuildContext context, String itemName, int price) {
    showDialog(
      context: context,
      builder: (context) {
        int quantity = 1;
        final Set<String> selectedModifiers = {};

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPallete.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppPallete.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Rp $price',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPallete.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _QtyButton(
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
                        _QtyButton(
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          [
                            'Less Ice',
                            'Extra Shot',
                            'Less Sugar',
                            'No Dairy',
                          ].map((modifier) {
                            final isSelected = selectedModifiers.contains(
                              modifier,
                            );
                            return _ModifierBadge(
                              label: modifier,
                              isSelected: isSelected,
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    selectedModifiers.remove(modifier);
                                  } else {
                                    selectedModifiers.add(modifier);
                                  }
                                });
                              },
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 16),
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
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _selectedCategory == 'All'
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories
                .map(
                  (category) => _CategoryBadge(
                    label: category,
                    isSelected: _selectedCategory == category,
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                )
                .toList(),
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

                return _MenuItemCard(
                  name: item['name'] as String,
                  price: item['price'] as int,
                  onAdd: () => _showModifierDialog(
                    context,
                    item['name'] as String,
                    item['price'] as int,
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

class _MenuItemCard extends StatelessWidget {
  final String name;
  final int price;
  final VoidCallback onAdd;

  const _MenuItemCard({
    required this.name,
    required this.price,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPallete.divider),
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/default-food.jpg',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: AppPallete.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Rp $price',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppPallete.primary),
              ),
              const SizedBox(height: 28),
            ],
          ),
          Positioned(
            right: 6,
            bottom: 6,
            child: InkWell(
              onTap: onAdd,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppPallete.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  color: AppPallete.onPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModifierBadge extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModifierBadge({
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppPallete.primary : AppPallete.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppPallete.primary : AppPallete.divider,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: isSelected ? AppPallete.onPrimary : AppPallete.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppPallete.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppPallete.divider),
        ),
        child: Icon(icon, size: 18, color: AppPallete.textPrimary),
      ),
    );
  }
}
