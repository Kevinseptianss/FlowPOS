import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/datetime_formatter.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_order_detail_page.dart';
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
  late final OrderBloc _orderBloc;

  int _totalRevenue = 0;
  int _qrisRevenue = 0;
  int _cashRevenue = 0;
  int _totalOrders = 0;

  List<OrderEntity> _orders = [];
  
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _orderBloc = context.read<OrderBloc>();
    _fetchData();
  }

  void _fetchData() {
    _orderBloc.add(GetRevenueRangeEvent(
      startDate: _startDate,
      endDate: _endDate,
    ));
    _orderBloc.add(GetAllOrdersEvent());
  }

  void _onDateRangeTap() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppPallete.primary,
              onPrimary: Colors.white,
              onSurface: AppPallete.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchData();
    }
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
            _orders = state.orders.where((order) {
              final date = order.createdAt;
              final start = DateTime(_startDate.year, _startDate.month, _startDate.day);
              final end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
              return date.isAfter(start.subtract(const Duration(seconds: 1))) && 
                     date.isBefore(end.add(const Duration(seconds: 1)));
            }).toList();
          });
        } else if (state is OrderFailure) {
          showSnackbar(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppPallete.background,
        body: RefreshIndicator(
          onRefresh: () async => _fetchData(),
          child: CustomScrollView(
            slivers: [
              // Unified Header Section
              SliverToBoxAdapter(child: _buildHeader(context)),
              
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              
              // Secondary Analytics Grid
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(child: _buildAnalyticGrid(context)),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
              
              // Transaction History Section
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Riwayat Transaksi',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppPallete.textPrimary,
                            ),
                      ),
                      Text(
                        '${_orders.length} Pesanan',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppPallete.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
              
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: _buildOrderHistorySliver(context),
              ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 48)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final dateRangeStr = _startDate.day == _endDate.day && 
                         _startDate.month == _endDate.month && 
                         _startDate.year == _endDate.year
        ? DatetimeFormatter.formatDateYear(_startDate)
        : '${DatetimeFormatter.formatDateYear(_startDate)} - ${DatetimeFormatter.formatDateYear(_endDate)}';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppPallete.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analisis Bisnis',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                  InkWell(
                    onTap: _onDateRangeTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(40),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _onDateRangeTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withAlpha(50)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_rounded, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          dateRangeStr,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Hero Metric Card (Integrated directly into header space)
          _buildHeroRevenueCard(context),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeroRevenueCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
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
          children: [
            Text(
              'Total Pendapatan',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppPallete.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                return state is OrderRevenueLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      )
                    : Text(
                        formatRupiah(_totalRevenue),
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppPallete.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(),
            ),
            Row(
              children: [
                _buildPaymentMethodSplit(
                  context,
                  label: 'QRIS',
                  value: formatRupiah(_qrisRevenue),
                  color: Colors.blueAccent,
                  icon: Icons.qr_code_2_rounded,
                ),
                Container(height: 30, width: 1, color: AppPallete.divider),
                _buildPaymentMethodSplit(
                  context,
                  label: 'Tunai',
                  value: formatRupiah(_cashRevenue),
                  color: AppPallete.success,
                  icon: Icons.payments_outlined,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSplit(BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticGrid(BuildContext context) {
    final aov = _totalOrders == 0 ? 0 : (_totalRevenue ~/ _totalOrders);
    
    final Map<String, int> productCounts = {};
    for (var order in _orders) {
      for (var item in order.items) {
        productCounts[item.menuName] = (productCounts[item.menuName] ?? 0) + item.quantity;
      }
    }
    
    final sortedProducts = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final topProduct = sortedProducts.isEmpty ? '-' : sortedProducts.first.key;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSimpleAnalyticCard(
                context,
                title: 'Rata-rata/Pesanan',
                value: formatRupiah(aov),
                icon: Icons.analytics_outlined,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSimpleAnalyticCard(
                context,
                title: 'Total Pesanan',
                value: '$_totalOrders',
                icon: Icons.shopping_bag_outlined,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSimpleAnalyticCard(
          context,
          title: 'Produk Terlaris Saat Ini',
          value: topProduct,
          icon: Icons.star_rounded,
          color: Colors.amber,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildSimpleAnalyticCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppPallete.textSecondary,
                      ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppPallete.textPrimary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHistorySliver(BuildContext context) {
    return BlocBuilder<OrderBloc, OrderState>(
      builder: (context, state) {
        if (state is OrdersLoading && _orders.isEmpty) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (_orders.isEmpty) {
          return SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.history_rounded, size: 64, color: AppPallete.divider),
                    const SizedBox(height: 16),
                    Text(
                      'Tidak ada transaksi untuk periode ini',
                      style: TextStyle(color: AppPallete.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final order = _orders[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OrderCard(
                  orderId: order.orderNumber,
                  paymentType: order.payment.method,
                  datetime: DatetimeFormatter.formatDateTime(order.createdAt),
                  totalItems: order.items.length,
                  totalPayment: formatRupiah(order.total),
                  onTap: () {
                    Navigator.push(context, OwnerOrderDetailPage.route(order));
                  },
                ),
              );
            },
            childCount: _orders.length,
          ),
        );
      },
    );
  }
}
