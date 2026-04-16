import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/datetime_formatter.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_order_detail_page.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:flow_pos/features/shift/presentation/bloc/shift_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

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
    await Future.delayed(const Duration(milliseconds: 600));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrdersLoaded) {
          final shiftState = context.read<ShiftBloc>().state;
          final currentShiftId = shiftState is ShiftOpened ? shiftState.shift.id : null;

          setState(() {
            _orders = state.orders
                .where((o) => 
                  (currentShiftId == null || o.shiftId == currentShiftId)
                )
                .toList()
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppPallete.background,
        appBar: AppBar(
          title: Text(
            'Riwayat Transaksi',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, 
              fontSize: 22,
              color: AppPallete.textPrimary,
            ),
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: AppPallete.textPrimary),
        ),
        body: Column(
          children: [
            _HistoryHeroHeader(orders: _orders),
            Expanded(
              child: BlocBuilder<OrderBloc, OrderState>(
                builder: (context, state) {
                  if (state is OrdersLoading && _orders.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is OrderFailure && _orders.isEmpty) {
                    return _buildErrorState();
                  }

                  return RefreshIndicator(
                    onRefresh: _refreshOrders,
                    displacement: 20,
                    color: AppPallete.primary,
                    child: _orders.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                                parent: BouncingScrollPhysics()),
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                            itemCount: _orders.length,
                            itemBuilder: (context, index) {
                              final order = _orders[index];
                              return _ModernHistoryOrderCard(
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

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppPallete.error.withAlpha(150)),
            const SizedBox(height: 16),
            Text(
              'Gagal memuat riwayat transaksi. Tarik ke bawah untuk mencoba lagi.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: AppPallete.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppPallete.surface,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    )
                  ],
                ),
                child: Icon(Icons.receipt_long_rounded, size: 64, color: AppPallete.divider),
              ),
              const SizedBox(height: 24),
              Text(
                'Belum Ada Transaksi',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Transaksi yang berhasil akan muncul di sini.',
                style: GoogleFonts.outfit(
                  color: AppPallete.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryHeroHeader extends StatelessWidget {
  final List<OrderEntity> orders;

  const _HistoryHeroHeader({required this.orders});

  @override
  Widget build(BuildContext context) {
    final paidOrders = orders.where((o) => o.status == 'PAID' || o.status == 'TERBAYAR').toList();
    final revenue = paidOrders.fold<int>(0, (sum, order) => sum + order.total);
    final totalCount = paidOrders.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppPallete.primary, AppPallete.primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppPallete.primary.withAlpha(60),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Pendapatan',
                      style: GoogleFonts.outfit(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatRupiah(revenue),
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.account_balance_wallet_rounded, 
                    color: Colors.white, size: 28),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              height: 1,
              color: Colors.white12,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                _MiniStat(
                  icon: Icons.receipt_long_rounded,
                  label: 'Pesanan',
                  value: '$totalCount',
                ),
                Container(width: 1, height: 30, color: Colors.white12, 
                  margin: const EdgeInsets.symmetric(horizontal: 20)),
                _MiniStat(
                  icon: Icons.show_chart_rounded,
                  label: 'Rata-rata',
                  value: totalCount == 0 ? 'Rp 0' : formatRupiah((revenue / totalCount).round()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Colors.white60, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(color: Colors.white60, fontSize: 11)),
            Text(value, style: GoogleFonts.outfit(color: Colors.white, 
              fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }
}

class _ModernHistoryOrderCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onTap;

  const _ModernHistoryOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final paymentMethod = (order.payment?.method ?? '').toUpperCase();
    final bool isQris = paymentMethod == 'QRIS' || 
                        (order.paymentLink != null && order.paymentLink!.isNotEmpty);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.orderNumber,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppPallete.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DatetimeFormatter.formatIndonesian(order.createdAt, includeTime: true),
                          style: GoogleFonts.outfit(
                            color: AppPallete.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    _StatusBadge(status: order.status),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _IconInfoPill(
                      icon: Icons.table_restaurant_rounded,
                      label: order.tableNumber == 0 ? 'Takeaway' : 'Meja ${order.tableNumber}',
                      color: AppPallete.primary,
                    ),
                    const SizedBox(width: 8),
                    _IconInfoPill(
                      icon: isQris ? Icons.qr_code_rounded : Icons.payments_rounded,
                      label: (paymentMethod.isNotEmpty && paymentMethod != 'NONE')
                          ? paymentMethod
                          : (isQris ? 'QRIS' : 'CASH'),
                      color: isQris ? Colors.deepPurple : Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1, thickness: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${order.items.length} Item',
                      style: GoogleFonts.outfit(
                        color: AppPallete.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      formatRupiah(order.total),
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppPallete.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isPaid = status == 'PAID' || status == 'TERBAYAR';
    final bool isVoided = status == 'VOIDED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isVoided 
            ? Colors.red.withAlpha(30) 
            : (isPaid ? Colors.green.withAlpha(25) : Colors.orange.withAlpha(25)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isVoided ? 'DIBATALKAN' : (isPaid ? 'TERBAYAR' : 'PENDING'),
        style: GoogleFonts.outfit(
          color: isVoided ? Colors.red : (isPaid ? Colors.green : Colors.orange),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _IconInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _IconInfoPill({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
