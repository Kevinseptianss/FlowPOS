import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/datetime_formatter.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_order_detail_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/order_card.dart';
import 'package:flow_pos/features/staff/data/datasources/salary_remote_data_source.dart';
import 'package:flow_pos/features/staff/data/models/salary_report_model.dart';
import 'package:flow_pos/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

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
  int _transferRevenue = 0;
  int _cardRevenue = 0;
  int _totalOrders = 0;
  int _totalSalary = 0;
  List<SalaryReportModel> _finalizedSalaries = [];

  List<OrderEntity> _orders = [];

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();

  final _salaryDataSource = SalaryRemoteDataSourceImpl(FirebaseFirestore.instance);

  @override
  void initState() {
    super.initState();
    _orderBloc = context.read<OrderBloc>();
    _fetchData();
  }

  void _fetchData() {
    _orderBloc.add(
      GetRevenueRangeEvent(startDate: _startDate, endDate: _endDate),
    );
    _orderBloc.add(GetAllOrdersEvent());
    context.read<StaffBloc>().add(GetStaffEvent());
    _fetchFinalizedSalaries();
  }

  Future<void> _fetchFinalizedSalaries() async {
    try {
      final reports = await _salaryDataSource.getSalaryReportsByRange(
        DateTime(_startDate.year, _startDate.month, _startDate.day),
        DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59),
      );
      
      if (mounted) {
        setState(() {
          _finalizedSalaries = reports;
          _totalSalary = reports.fold(0, (sum, report) => sum + report.netPay);
        });
      }
    } catch (e) {
      debugPrint('Error fetching salaries: $e');
    }
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
    return MultiBlocListener(
      listeners: [
        BlocListener<OrderBloc, OrderState>(
          listener: (context, state) {
        if (state is OrderRevenueLoaded) {
          setState(() {
            _totalRevenue = state.revenue.totalRevenue;
            _qrisRevenue = state.revenue.totalQrisRevenue;
            _cashRevenue = state.revenue.totalCashRevenue;
            _transferRevenue = state.revenue.totalTransferRevenue;
            _cardRevenue = state.revenue.totalCardRevenue;
            _totalOrders = state.revenue.totalOrders;
          });
        } else if (state is OrdersLoaded) {
          setState(() {
            _orders = state.orders.where((order) {
              final isPaid = order.status == 'PAID';
              if (!isPaid) return false;

              final date = order.createdAt;
              final start = DateTime(
                _startDate.year,
                _startDate.month,
                _startDate.day,
              );
              final end = DateTime(
                _endDate.year,
                _endDate.month,
                _endDate.day,
                23,
                59,
                59,
              );
              return date.isAfter(start.subtract(const Duration(seconds: 1))) &&
                  date.isBefore(end.add(const Duration(seconds: 1)));
            }).toList();
          });
          } else if (state is OrderFailure) {
            showSnackbar(context, state.message);
          }
        },
        ),
        BlocListener<StaffBloc, StaffState>(
          listener: (context, state) {
            // No longer summing projected salaries here
            // We fetch finalized reports in _fetchFinalizedSalaries()
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppPallete.background,
        resizeToAvoidBottomInset: false,
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
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Riwayat Transaksi',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppPallete.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppPallete.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_orders.length} Pesanan',
                          style: GoogleFonts.outfit(
                            color: AppPallete.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
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

              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final dateRangeStr =
        _startDate.day == _endDate.day &&
            _startDate.month == _endDate.month &&
            _startDate.year == _endDate.year
        ? DatetimeFormatter.formatDateYear(_startDate)
        : '${DatetimeFormatter.formatDateYear(_startDate)} - ${DatetimeFormatter.formatDateYear(_endDate)}';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppPallete.primary, AppPallete.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ANALISIS BISNIS',
                        style: GoogleFonts.outfit(
                          color: Colors.white.withAlpha(180),
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ringkasan Owner',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withAlpha(40)),
                    ),
                    child: IconButton(
                      onPressed: _onDateRangeTap,
                      icon: const Icon(
                        Icons.calendar_today_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                InkWell(
                  onTap: _onDateRangeTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(30),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withAlpha(40)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.timer_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          dateRangeStr,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          _buildHeroRevenueCard(context),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildHeroRevenueCard(BuildContext context) {
    final int netProfit = _totalRevenue - _totalSalary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppPallete.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 30,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.insights_rounded,
                  color: AppPallete.primary.withAlpha(150),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'TOTAL PENDAPATAN',
                  style: GoogleFonts.outfit(
                    color: AppPallete.textSecondary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BlocBuilder<OrderBloc, OrderState>(
              builder: (context, state) {
                if (state is OrderRevenueLoading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(
                        backgroundColor: AppPallete.divider,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  );
                }
                return Text(
                  formatRupiah(_totalRevenue),
                  style: GoogleFonts.outfit(
                    color: AppPallete.textPrimary,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.5,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Profit Breakdown
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: AppPallete.background.withAlpha(100),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppPallete.divider.withAlpha(50)),
              ),
              child: Column(
                children: [
                  _buildProfitDetailRow(
                    label: 'Gaji Karyawan',
                    value: '- ${formatRupiah(_totalSalary)}',
                    color: Colors.redAccent,
                    isBold: false,
                  ),
                  if (_finalizedSalaries.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: _finalizedSalaries.map((s) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person_outline_rounded, size: 12, color: AppPallete.textSecondary.withAlpha(150)),
                                  const SizedBox(width: 6),
                                  Text(
                                    s.staffName,
                                    style: GoogleFonts.outfit(fontSize: 11, color: AppPallete.textSecondary),
                                  ),
                                ],
                              ),
                              Text(
                                formatRupiah(s.netPay),
                                style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: AppPallete.textPrimary.withAlpha(200)),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Divider(height: 1, thickness: 1),
                  ),
                  _buildProfitDetailRow(
                    label: 'LABA BERSIH',
                    value: formatRupiah(netProfit),
                    color: netProfit >= 0 ? AppPallete.success : Colors.red,
                    isBold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppPallete.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildPaymentSplitItem(
                        label: 'QRIS',
                        value: formatRupiah(_qrisRevenue),
                        icon: Icons.qr_code_2_rounded,
                        color: Colors.blueAccent,
                      ),
                      Container(width: 1, height: 40, color: AppPallete.divider, margin: const EdgeInsets.symmetric(horizontal: 10)),
                      _buildPaymentSplitItem(
                        label: 'TUNAI',
                        value: formatRupiah(_cashRevenue),
                        icon: Icons.payments_outlined,
                        color: AppPallete.success,
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1),
                  ),
                  Row(
                    children: [
                      _buildPaymentSplitItem(
                        label: 'TRANSFER',
                        value: formatRupiah(_transferRevenue),
                        icon: Icons.account_balance_rounded,
                        color: Colors.indigoAccent,
                      ),
                      Container(width: 1, height: 40, color: AppPallete.divider, margin: const EdgeInsets.symmetric(horizontal: 10)),
                      _buildPaymentSplitItem(
                        label: 'KARTU',
                        value: formatRupiah(_cardRevenue),
                        icon: Icons.credit_card_rounded,
                        color: Colors.orangeAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitDetailRow({
    required String label,
    required String value,
    required Color color,
    required bool isBold,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: AppPallete.textSecondary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSplitItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: AppPallete.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: AppPallete.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
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
        productCounts[item.menuName] =
            (productCounts[item.menuName] ?? 0) + item.quantity;
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
                title: 'AOV (Rata-rata)',
                value: formatRupiah(aov),
                icon: Icons.auto_graph_rounded,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSimpleAnalyticCard(
                context,
                title: 'Total Pesanan',
                value: '$_totalOrders',
                icon: Icons.receipt_long_rounded,
                color: Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSimpleAnalyticCard(
          context,
          title: 'Produk Terlaris',
          value: topProduct,
          icon: Icons.star_rounded,
          color: Colors.amber,
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildSimpleAnalyticCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPallete.divider),
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: AppPallete.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: AppPallete.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
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
              padding: const EdgeInsets.symmetric(vertical: 60),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppPallete.divider.withAlpha(50),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        size: 64,
                        color: AppPallete.divider,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Belum Ada Transaksi',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppPallete.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Riwayat transaksi Anda akan muncul di sini.',
                      style: GoogleFonts.outfit(
                        color: AppPallete.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final order = _orders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: OrderCard(
                orderId: order.orderNumber,
                paymentType:
                    order.payment?.method ??
                    (order.status == 'UNPAID' ? 'MEJA (PENDING)' : 'LUNAS'),
                datetime: DatetimeFormatter.formatIndonesian(
                  order.createdAt,
                  includeTime: true,
                ),
                totalItems: order.items.length,
                totalPayment: formatRupiah(order.total),
                onTap: () {
                  Navigator.push(context, OwnerOrderDetailPage.route(order));
                },
              ),
            );
          }, childCount: _orders.length),
        );
      },
    );
  }
}
