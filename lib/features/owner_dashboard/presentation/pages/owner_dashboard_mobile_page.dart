import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/datetime_formatter.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/add_menu_dialog.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/menu_card.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/order_card.dart';
import 'package:flutter/material.dart';

class OwnerDashboardMobilePage extends StatefulWidget {
  const OwnerDashboardMobilePage({super.key});

  @override
  State<OwnerDashboardMobilePage> createState() =>
      _OwnerDashboardMobilePageState();
}

class _OwnerDashboardMobilePageState extends State<OwnerDashboardMobilePage> {
  bool _isOrderHistorySelected = true;

  static const int _totalRevenue = 1500000;
  static const int _qrisRevenue = 1000000;
  static const int _cashRevenue = 500000;
  static final int _totalOrders = _orders.length;

  static const List<Map<String, dynamic>> _orders = [
    {
      'orderId': 'ORD-001',
      'paymentType': 'QRIS',
      'datetime': '2026-03-14 10:30',
      'totalItems': 5,
      'totalPayment': '150.000',
    },
    {
      'orderId': 'ORD-002',
      'paymentType': 'Cash',
      'datetime': '2026-03-14 11:15',
      'totalItems': 3,
      'totalPayment': '75.000',
    },
    {
      'orderId': 'ORD-003',
      'paymentType': 'QRIS',
      'datetime': '2026-03-14 12:00',
      'totalItems': 7,
      'totalPayment': '200.000',
    },
    {
      'orderId': 'ORD-004',
      'paymentType': 'Cash',
      'datetime': '2026-03-14 12:45',
      'totalItems': 2,
      'totalPayment': '50.000',
    },
    {
      'orderId': 'ORD-005',
      'paymentType': 'QRIS',
      'datetime': '2026-03-14 13:30',
      'totalItems': 4,
      'totalPayment': '120.000',
    },
    {
      'orderId': 'ORD-006',
      'paymentType': 'Cash',
      'datetime': '2026-03-15 09:20',
      'totalItems': 6,
      'totalPayment': '180.000',
    },
  ];

  static const List<Map<String, dynamic>> _menuItems = [
    {
      'name': 'Iced Americano',
      'price': 15000,
      'category': 'Beverage',
      'enabled': true,
      'image': 'assets/images/default-food.jpg',
    },
    {
      'name': 'Cappuccino',
      'price': 22000,
      'category': 'Beverage',
      'enabled': true,
      'image': 'assets/images/default-food.jpg',
    },
    {
      'name': 'Chocolate Croissant',
      'price': 18000,
      'category': 'Pastry',
      'enabled': true,
      'image': 'assets/images/default-food.jpg',
    },
    {
      'name': 'Chicken Sandwich',
      'price': 28000,
      'category': 'Food',
      'enabled': false,
      'image': 'assets/images/default-food.jpg',
    },
    {
      'name': 'Matcha Latte',
      'price': 25000,
      'category': 'Beverage',
      'enabled': true,
      'image': 'assets/images/default-food.jpg',
    },
  ];

  String _formatRupiah(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp ${buffer.toString()}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        backgroundColor: AppPallete.primary,
        elevation: 0,
        toolbarHeight: 84,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Owner Dashboard',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppPallete.onPrimary),
            ),
            const SizedBox(height: 2),
            Text(
              DatetimeFormatter.formatDateYear(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppPallete.onPrimary.withAlpha(220),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.settings_outlined),
            color: AppPallete.onPrimary,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: AppPallete.primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppPallete.surface,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.trending_up,
                        color: AppPallete.success,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Total Revenue',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppPallete.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatRupiah(_totalRevenue),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppPallete.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.qr_code,
                              color: AppPallete.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _formatRupiah(_qrisRevenue),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: AppPallete.primary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.money,
                              color: AppPallete.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _formatRupiah(_cashRevenue),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: AppPallete.primary),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '$_totalOrders orders in this month',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppPallete.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: AppPallete.surface,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: _OwnerTabButton(
                    label: 'Order History',
                    selected: _isOrderHistorySelected,
                    onTap: () {
                      setState(() {
                        _isOrderHistorySelected = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _OwnerTabButton(
                    label: 'Menu Settings',
                    selected: !_isOrderHistorySelected,
                    onTap: () {
                      setState(() {
                        _isOrderHistorySelected = false;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppPallete.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isOrderHistorySelected
                  ? ListView.builder(
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return OrderCard(
                          orderId: order['orderId'] as String,
                          paymentType: order['paymentType'] as String,
                          datetime: order['datetime'] as String,
                          totalItems: order['totalItems'] as int,
                          totalPayment: order['totalPayment'] as String,
                        );
                      },
                    )
                  : ListView.builder(
                      itemCount: _menuItems.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _AddMenuOrCategoryCard(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => const AddMenuDialog(),
                              );
                            },
                          );
                        }

                        final menuItem = _menuItems[index - 1];
                        return MenuCard(
                          title: menuItem['name'] as String,
                          price: menuItem['price'] as int,
                          category: menuItem['category'] as String,
                          enabled: menuItem['enabled'] as bool,
                          image: Image.asset(menuItem['image'] as String),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OwnerTabButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _OwnerTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 42,
        decoration: BoxDecoration(
          color: selected ? AppPallete.primary : AppPallete.background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppPallete.primary : AppPallete.divider,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: selected ? AppPallete.onPrimary : AppPallete.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _AddMenuOrCategoryCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddMenuOrCategoryCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: AppPallete.background,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 72,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_circle_outline, color: AppPallete.primary),
              const SizedBox(width: 8),
              Text(
                'Add Menu or Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppPallete.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
