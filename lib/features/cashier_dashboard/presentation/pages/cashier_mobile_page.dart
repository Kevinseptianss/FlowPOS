import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/list_order_section.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/menu_item_card.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/modifier_dialog.dart';
import 'package:flow_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashierMobilePage extends StatefulWidget {
  const CashierMobilePage({super.key});

  @override
  State<CashierMobilePage> createState() => _CashierMobilePageState();
}

class _CashierMobilePageState extends State<CashierMobilePage> {
  static const String _cashierName = 'Jason';

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

  static const List<Map<String, dynamic>> _orderItems = [
    {'name': 'Iced Americano', 'qty': 2, 'price': 15000},
    {'name': 'Chicken Sandwich', 'qty': 1, 'price': 28000},
    {'name': 'Chocolate Croissant', 'qty': 1, 'price': 18000},
    {'name': 'Matcha Latte', 'qty': 3, 'price': 25000},
    {'name': 'French Fries', 'qty': 2, 'price': 20000},
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

    return Scaffold(
      backgroundColor: AppPallete.background,
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: AppPallete.primary,
        elevation: 0,
        toolbarHeight: 78,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'FlowPOS',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppPallete.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Cashier: $_cashierName',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppPallete.onPrimary.withAlpha(220),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 86),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: AppPallete.primary,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                    child: BlocBuilder<CategoryBloc, CategoryState>(
                      builder: (context, state) {
                        if (state is CategoryLoading) {
                          return const Text('Loading categories...');
                        } else if (state is CategoryFailure) {
                          return Text('Error: ${state.message}');
                        } else if (state is CategoryLoaded) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: state.categories
                                  .map(
                                    (category) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _CategoryBadge(
                                        label: category.name,
                                        isSelected:
                                            _selectedCategory == category.id,
                                        onTap: () {
                                          setState(() {
                                            _selectedCategory = category.id;
                                          });
                                        },
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          );
                        } else {
                          return const SizedBox();
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: GridView.builder(
                        itemCount: filteredItems.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.78,
                            ),
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];

                          return MenuItemCard(
                            name: item['name'] as String,
                            price: item['price'] as int,
                            onAdd: () {
                              showDialog(
                                context: context,
                                builder: (context) => ModifierDialog(
                                  itemName: item['name'] as String,
                                  price: item['price'] as int,
                                  modifierGroups: _modifierGroups,
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: AppPallete.surface,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled:
                              true, // WAJIB jika memiliki child yang bisa di-scroll
                          backgroundColor: Colors.transparent,
                          builder: (context) {
                            return Container(
                              height: MediaQuery.of(context).size.height * 0.78,
                              decoration: const BoxDecoration(
                                color: AppPallete.surface,
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(20),
                                ),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: ListOrderSection(),
                              ),
                            );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPallete.primary,
                        foregroundColor: AppPallete.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'View Cart (${_orderItems.length})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppPallete.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
          color: isSelected ? AppPallete.surface : AppPallete.primary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppPallete.surface : AppPallete.onPrimary,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected ? AppPallete.primary : AppPallete.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
