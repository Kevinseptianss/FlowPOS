import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/datetime_formatter.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_order_detail_page.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashierHistoryPage extends StatefulWidget {
  const CashierHistoryPage({super.key});

  @override
  State<CashierHistoryPage> createState() => _CashierHistoryPageState();
}

class _CashierHistoryPageState extends State<CashierHistoryPage> {
  late final OrderBloc _orderBloc;
  List<OrderEntity> _orders = [];

  @override
  void initState() {
    super.initState();
    _orderBloc = context.read<OrderBloc>();
    _orderBloc.add(GetAllOrdersEvent());
  }

  Future<void> _refreshOrders() async {
    _orderBloc.add(GetAllOrdersEvent());
    await Future.delayed(const Duration(milliseconds: 450));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrdersLoaded) {
          setState(() {
            _orders = List<OrderEntity>.from(state.orders)
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Order History'), centerTitle: false),
        body: Column(
          children: [
            _HistoryHeader(orders: _orders),
            Expanded(
              child: BlocBuilder<OrderBloc, OrderState>(
                builder: (context, state) {
                  if (state is OrdersLoading && _orders.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is OrderFailure && _orders.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          'Unable to load order history. Pull to refresh and try again.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(color: AppPallete.error),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshOrders,
                    child: _orders.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.42,
                                child: Center(
                                  child: Text(
                                    'No transactions yet',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppPallete.textPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 22),
                            itemCount: _orders.length,
                            separatorBuilder: (_, index) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final order = _orders[index];
                              return _CashierHistoryOrderCard(
                                order: order,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    CashierOrderDetailPage.route(order),
                                  );
                                },
                              );
                            },
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  final List<OrderEntity> orders;

  const _HistoryHeader({required this.orders});

  @override
  Widget build(BuildContext context) {
    final revenue = orders.fold<int>(0, (sum, order) => sum + order.total);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPallete.primary, AppPallete.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(18),
          bottomRight: Radius.circular(18),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryPill(
              label: 'Orders',
              value: '${orders.length}',
              icon: Icons.receipt_long,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _SummaryPill(
              label: 'Revenue',
              value: formatRupiah(revenue),
              icon: Icons.payments_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryPill({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(28),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withAlpha(30)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppPallete.onPrimary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppPallete.onPrimary.withAlpha(230),
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppPallete.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CashierHistoryOrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onTap;

  const _CashierHistoryOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppPallete.surface,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppPallete.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppPallete.primary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DatetimeFormatter.formatDateTime(order.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppPallete.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  _MethodBadge(method: order.payment.method),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _InfoChip(
                    icon: Icons.table_restaurant,
                    label: 'Table T${order.tableNumber}',
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.shopping_bag_outlined,
                    label: '${order.items.length} items',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPallete.textPrimary,
                    ),
                  ),
                  Text(
                    formatRupiah(order.total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppPallete.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  final String method;

  const _MethodBadge({required this.method});

  @override
  Widget build(BuildContext context) {
    final isQris = method.toUpperCase() == 'QRIS';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isQris ? AppPallete.primary : AppPallete.secondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        method,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppPallete.onPrimary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppPallete.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppPallete.textPrimary),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppPallete.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
