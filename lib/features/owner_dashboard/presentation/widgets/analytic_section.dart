import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'analytic_card.dart';
import 'income_card.dart';

class AnalyticSection extends StatefulWidget {
  const AnalyticSection({super.key});

  @override
  State<AnalyticSection> createState() => _AnalyticSectionState();
}

class _AnalyticSectionState extends State<AnalyticSection> {
  int _totalRevenue = 0;
  int _totalOrders = 0;
  int _qrisRevenue = 0;
  int _cashRevenue = 0;
  int _transferRevenue = 0;
  int _cardRevenue = 0;

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(
      GetRevenueRangeEvent(
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderRevenueLoaded) {
          setState(() {
            _totalRevenue = state.revenue.totalRevenue;
            _totalOrders = state.revenue.totalOrders;
            _qrisRevenue = state.revenue.totalQrisRevenue;
            _cashRevenue = state.revenue.totalCashRevenue;
            _transferRevenue = state.revenue.totalTransferRevenue;
            _cardRevenue = state.revenue.totalCardRevenue;
          });
        } else if (state is OrderFailure) {
          showSnackbar(context, state.message);
        }
      },
      child: BlocBuilder<OrderBloc, OrderState>(
        builder: (context, state) {
          final avgOrder = _totalOrders == 0
              ? 0
              : (_totalRevenue ~/ _totalOrders);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ... existing widgets ...
              Row(
                children: [
                  Expanded(
                    child: AnalyticCard(
                      icon: Icons.trending_up_rounded,
                      title: 'Pendapatan',
                      value: formatRupiah(_totalRevenue),
                      color: AppPallete.primary,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: AnalyticCard(
                      icon: Icons.shopping_bag_outlined,
                      title: 'Pesanan',
                      value: '$_totalOrders',
                      color: Colors.orangeAccent,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: AnalyticCard(
                      icon: Icons.analytics_outlined,
                      title: 'Rata-rata/Pesanan',
                      value: formatRupiah(avgOrder),
                      color: Colors.indigoAccent,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: AnalyticCard(
                      icon: Icons.restaurant_menu_rounded,
                      title: 'Menu Aktif',
                      value: '12',
                      color: AppPallete.success,
                    ),
                  ),
                ],
              ),
              if (state is OrderRevenueLoading) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(
                  minHeight: 6,
                ),
              ],
              const SizedBox(height: 24),
              IncomeCard(
                qrisRevenue: _qrisRevenue, 
                cashRevenue: _cashRevenue,
                transferRevenue: _transferRevenue,
                cardRevenue: _cardRevenue,
              ),
            ],
          );
        },
      ),
    );
  }
}
