import 'package:dotted_border/dotted_border.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/datetime_formatter.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/menu_item/presentation/bloc/menu_item_bloc.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_order_detail_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_menu_item_detail_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/add_menu_dialog.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/menu_card.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/order_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OwnerDashboardMobilePage extends StatefulWidget {
  const OwnerDashboardMobilePage({super.key});

  @override
  State<OwnerDashboardMobilePage> createState() =>
      _OwnerDashboardMobilePageState();
}

class _OwnerDashboardMobilePageState extends State<OwnerDashboardMobilePage> {
  bool _isOrderHistorySelected = true;

  late final OrderBloc _orderBloc;
  late final MenuItemBloc _menuItemBloc;

  int _totalRevenue = 0;
  int _qrisRevenue = 0;
  int _cashRevenue = 0;
  int _totalOrders = 0;

  List<OrderEntity> _orders = [];

  @override
  void initState() {
    super.initState();
    _orderBloc = context.read<OrderBloc>();
    _menuItemBloc = context.read<MenuItemBloc>();

    _orderBloc.add(GetMonthlyRevenueEvent(month: DateTime.now()));
    _orderBloc.add(GetAllOrdersEvent());
    _menuItemBloc.add(GetAllMenuItemsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderRevenueLoaded) {
          setState(() {
            _totalRevenue = state.revenue.totalRevenue;
            _qrisRevenue = state.revenue.totalQrisRevenue;
            _cashRevenue = state.revenue.totalCashRevenue;
            _totalOrders = state.revenue.totalOrders;
          });
        } else if (state is OrdersLoaded) {
          setState(() {
            _orders = state.orders;
          });
        } else if (state is OrderFailure) {
          showSnackbar(context, state.message);
        }
      },
      child: Column(
        children: [
          _buildHeader(context),
          _buildStatsCard(context),
          _buildTabSection(context),
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppPallete.background,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _isOrderHistorySelected
                  ? _buildOrderHistory(context)
                  : _buildMenuSettings(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppPallete.primary, Color(0xFF6B48FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang,',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white.withAlpha(200),
                        ),
                  ),
                  Text(
                    'Dashboard Pemilik',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              const CircleAvatar(
                backgroundColor: Colors.white24,
                child: Icon(Icons.person_outline, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            DatetimeFormatter.formatDateYear(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withAlpha(180),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Pendapatan',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppPallete.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              BlocBuilder<OrderBloc, OrderState>(
                builder: (context, state) {
                  return Text(
                    formatRupiah(_totalRevenue),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppPallete.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMiniStat(
                    context,
                    label: 'QRIS',
                    value: formatRupiah(_qrisRevenue),
                    color: Colors.blueAccent,
                  ),
                  _buildMiniStat(
                    context,
                    label: 'Tunai',
                    value: formatRupiah(_cashRevenue),
                    color: AppPallete.success,
                  ),
                  _buildMiniStat(
                    context,
                    label: 'Pesanan',
                    value: '$_totalOrders',
                    color: Colors.orangeAccent,
                    isCount: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(BuildContext context,
      {required String label,
      required String value,
      required Color color,
      bool isCount = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppPallete.textSecondary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppPallete.textPrimary,
              ),
        ),
      ],
    );
  }

  Widget _buildTabSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppPallete.divider.withAlpha(50),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: _OwnerTabButton(
                label: 'Pesanan',
                selected: _isOrderHistorySelected,
                onTap: () => setState(() => _isOrderHistorySelected = true),
              ),
            ),
            Expanded(
              child: _OwnerTabButton(
                label: 'Menu',
                selected: !_isOrderHistorySelected,
                onTap: () => setState(() => _isOrderHistorySelected = false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHistory(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrdersLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () async {
            _orderBloc.add(GetMonthlyRevenueEvent(month: DateTime.now()));
            _orderBloc.add(GetAllOrdersEvent());
          },
          child: ListView.separated(
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: _orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = _orders[index];
              return OrderCard(
                orderId: order.orderNumber,
                paymentType: order.payment.method,
                datetime: DatetimeFormatter.formatDateTime(order.createdAt),
                totalItems: order.items.length,
                totalPayment: formatRupiah(order.total),
                onTap: () {
                  Navigator.push(context, OwnerOrderDetailPage.route(order));
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMenuSettings(BuildContext context) {
    return BlocBuilder<MenuItemBloc, MenuItemState>(
      builder: (context, state) {
        if (state is MenuItemLoading) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is MenuItemLoaded) {
          return RefreshIndicator(
            onRefresh: () async {
              _menuItemBloc.add(GetAllMenuItemsEvent());
            },
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: state.menuItems.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
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
                final menuItem = state.menuItems[index - 1];
                return MenuCard(
                  key: ValueKey(menuItem.id),
                  title: menuItem.name,
                  price: menuItem.price,
                  category: menuItem.category.name,
                  enabled: menuItem.enabled,
                  onTap: () {
                    Navigator.push(
                      context,
                      OwnerMenuItemDetailPage.route(menuItem),
                    );
                  },
                  onEnabledChanged: (value) {
                    _menuItemBloc.add(UpdateMenuItemAvailabilityEvent(
                      menuItemId: menuItem.id,
                      enabled: value,
                    ));
                  },
                  image: Image.asset('assets/images/default-food.jpg'),
                );
              },
            ),
          );
        }
        return const SizedBox();
      },
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
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 48,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected ? AppPallete.primary : AppPallete.textSecondary,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
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
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        radius: const Radius.circular(16),
        color: AppPallete.primary,
        strokeWidth: 1.5,
        dashPattern: const [8, 4],
        strokeCap: StrokeCap.round,
        padding: const EdgeInsets.all(2),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_circle,
                color: AppPallete.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Tambah Menu / Kategori',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppPallete.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
