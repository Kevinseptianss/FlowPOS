import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/add_menu_dialog.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/menu_card.dart';
import 'package:flutter/material.dart';

class ManageMenuSection extends StatelessWidget {
  const ManageMenuSection({super.key});

  static const List<Map<String, dynamic>> mockMenuData = [
    {
      'id': 'menu-001',
      'name': 'Iced Americano',
      'price': 15000,
      'category': 'Beverage',
      'enabled': true,
    },
    {
      'id': 'menu-002',
      'name': 'Cappuccino',
      'price': 22000,
      'category': 'Beverage',
      'enabled': true,
    },
    {
      'id': 'menu-003',
      'name': 'Chocolate Croissant',
      'price': 18000,
      'category': 'Pastry',
      'enabled': true,
    },
    {
      'id': 'menu-004',
      'name': 'Chicken Sandwich',
      'price': 28000,
      'category': 'Food',
      'enabled': false,
    },
    {
      'id': 'menu-005',
      'name': 'Matcha Latte',
      'price': 25000,
      'category': 'Beverage',
      'enabled': true,
    },
    {
      'id': 'menu-006',
      'name': 'Blueberry Muffin',
      'price': 20000,
      'category': 'Pastry',
      'enabled': true,
    },
    {
      'id': 'menu-007',
      'name': 'Grilled Cheese Sandwich',
      'price': 30000,
      'category': 'Food',
      'enabled': false,
    },
    {
      'id': 'menu-008',
      'name': 'Espresso',
      'price': 12000,
      'category': 'Beverage',
      'enabled': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppPallete.textPrimary.withAlpha(127)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menu Management',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddMenuDialog(),
                  );
                },
                child: Container(
                  padding: EdgeInsetsGeometry.all(5),
                  decoration: BoxDecoration(
                    color: AppPallete.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: AppPallete.onPrimary),
                ),
              ),
            ],
          ),
        ),
        // Menu List
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
            child: ListView.builder(
              itemCount: mockMenuData.length,
              itemBuilder: (context, index) {
                final menuItem = mockMenuData[index];
                return MenuCard(
                  title: menuItem['name'],
                  price: menuItem['price'],
                  category: menuItem['category'],
                  enabled: menuItem['enabled'],
                  image: menuItem['images'] == null
                      ? Image.asset('assets/images/default-food.jpg')
                      : Image.asset(menuItem['images']),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
