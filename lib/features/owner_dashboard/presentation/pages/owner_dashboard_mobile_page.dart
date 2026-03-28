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
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_settings_page.dart';
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

  int _totalRevenue = 0;
  int _qrisRevenue = 0;
  int _cashRevenue = 0;
  int _totalOrders = 0;

  List<OrderEntity> _orders = [];

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(
      StartMonthlyRevenueRealtimeEvent(month: DateTime.now()),
    );
    context.read<OrderBloc>().add(StartAllOrdersRealtimeEvent());
    context.read<MenuItemBloc>().add(StartMenuItemsRealtimeEvent());
  }

  @override
  void dispose() {
    context.read<OrderBloc>().add(StopOrderRealtimeEvent());
    context.read<MenuItemBloc>().add(StopMenuItemsRealtimeEvent());
    super.dispose();
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
      child: Scaffold(
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
              onPressed: () {
                Navigator.push(context, OwnerSettingsPage.route());
              },
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
                    BlocBuilder<OrderBloc, OrderState>(
                      builder: (context, state) {
                        if (state is OrderRevenueLoading) {
                          return const SizedBox(
                            height: 28,
                            width: 28,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          );
                        }

                        return Text(
                          formatRupiah(_totalRevenue),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppPallete.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        );
                      },
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
                                  formatRupiah(_qrisRevenue),
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
                                  formatRupiah(_cashRevenue),
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
                    ? BlocBuilder<OrderBloc, OrderState>(
                        builder: (context, state) {
                          if (state is OrdersLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (state is OrderFailure) {
                            return Center(
                              child: Text(
                                'Failed to load orders',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: AppPallete.error),
                              ),
                            );
                          } else {
                            return RefreshIndicator(
                              onRefresh: () async {
                                context.read<OrderBloc>().add(
                                  GetMonthlyRevenueEvent(month: DateTime.now()),
                                );
                                context.read<OrderBloc>().add(
                                  GetAllOrdersEvent(),
                                );

                                await Future.delayed(
                                  const Duration(seconds: 1),
                                );
                              },
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _orders.length,
                                itemBuilder: (context, index) {
                                  final order = _orders[index];
                                  return OrderCard(
                                    orderId: order.orderNumber,
                                    paymentType: order.payment.method,
                                    datetime: DatetimeFormatter.formatDateTime(
                                      order.createdAt,
                                    ),
                                    totalItems: order.items.length,
                                    totalPayment: formatRupiah(order.total),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        OwnerOrderDetailPage.route(order),
                                      );
                                    },
                                  );
                                },
                              ),
                            );
                          }
                        },
                      )
                    : BlocBuilder<MenuItemBloc, MenuItemState>(
                        builder: (context, state) {
                          if (state is MenuItemLoading) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          } else if (state is MenuItemFailure) {
                            return Center(
                              child: Text(
                                'Failed to load menu items',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: AppPallete.error),
                              ),
                            );
                          } else if (state is MenuItemLoaded) {
                            return RefreshIndicator(
                              onRefresh: () async {
                                context.read<MenuItemBloc>().add(
                                  GetAllMenuItemsEvent(),
                                );

                                await Future.delayed(
                                  const Duration(seconds: 1),
                                );
                              },
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: state.menuItems.length + 1,
                                itemBuilder: (context, index) {
                                  if (index == 0) {
                                    return _AddMenuOrCategoryCard(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) =>
                                              const AddMenuDialog(),
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
                                      context.read<MenuItemBloc>().add(
                                        UpdateMenuItemAvailabilityEvent(
                                          menuItemId: menuItem.id,
                                          enabled: value,
                                        ),
                                      );
                                    },
                                    image: Image.asset(
                                      'assets/images/default-food.jpg',
                                    ),
                                  );
                                },
                              ),
                            );
                          }

                          return const SizedBox();
                        },
                      ),
              ),
            ),
          ],
        ),
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
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        radius: const Radius.circular(12),
        color: AppPallete.primary,
        strokeWidth: 2,
        dashPattern: const [10, 4],
        strokeCap: StrokeCap.round,
        padding: EdgeInsets.all(3),
      ),
      child: Card(
        elevation: 2,
        margin: EdgeInsets.zero,
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
      ),
    );
  }
}
