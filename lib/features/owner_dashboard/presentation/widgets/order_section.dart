import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/datetime_formatter.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'order_card.dart';

class OrderSection extends StatelessWidget {
  final List<OrderEntity> orders;
  final void Function(OrderEntity order)? onOrderTap;

  const OrderSection({super.key, required this.orders, this.onOrderTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pesanan Terbaru',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppPallete.textPrimary,
                    ),
              ),
              TextButton(
                onPressed: () {
                  // TODO: Go to all orders
                },
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
        ),
        Expanded(
          child: orders.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<OrderBloc>().add(GetAllOrdersEvent());
                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: orders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return OrderCard(
                        orderId: order.orderNumber,
                        paymentType: order.payment?.method ?? (order.status == 'UNPAID' ? 'TAGIHAN MEJA' : 'LUNAS'),
                        datetime: DatetimeFormatter.formatDateTime(
                          order.createdAt,
                        ),
                        totalItems: order.items.length,
                        totalPayment: formatRupiah(order.total),
                        onTap: () => onOrderTap?.call(order),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: AppPallete.primary.withAlpha(50),
          ),
          const SizedBox(height: 16),
          Text(
            "Belum ada pesanan",
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppPallete.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}
