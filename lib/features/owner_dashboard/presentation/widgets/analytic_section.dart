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

  String _formatThousands(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      final reverseIndex = digits.length - i;
      buffer.write(digits[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(
      StartMonthlyRevenueRealtimeEvent(month: DateTime.now()),
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
            children: [
              Row(
                children: [
                  Expanded(
                    child: AnalyticCard(
                      icon: Icons.trending_up,
                      title: 'Revenue',
                      value: _formatThousands(_totalRevenue),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnalyticCard(
                      icon: Icons.shopping_cart,
                      title: 'Orders',
                      value: '$_totalOrders',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnalyticCard(
                      icon: Icons.calculate,
                      title: 'Avg/Orders',
                      value: _formatThousands(avgOrder),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AnalyticCard(
                      icon: Icons.inventory,
                      title: 'Active Items',
                      value: '12',
                    ),
                  ),
                ],
              ),
              if (state is OrderRevenueLoading) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(),
              ],
              const SizedBox(height: 16),
              IncomeCard(qrisRevenue: _qrisRevenue, cashRevenue: _cashRevenue),
            ],
          );
        },
      ),
    );
  }
}
