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

  const OrderSection({super.key, required this.orders});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Recent Orders',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: orders.isEmpty
              ? Center(
                  child: Text(
                    "Order is empty",
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppPallete.primary),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<OrderBloc>().add(GetAllOrdersEvent());

                    await Future.delayed(const Duration(seconds: 1));
                  },
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return OrderCard(
                        orderId: order.orderNumber,
                        paymentType: order.payment.method,
                        datetime: DatetimeFormatter.formatDateTime(
                          order.createdAt,
                        ),
                        totalItems: order.items.length,
                        totalPayment: formatRupiah(order.total),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
