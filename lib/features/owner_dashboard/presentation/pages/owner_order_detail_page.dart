import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/datetime_formatter.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flutter/material.dart';

class OwnerOrderDetailPage extends StatelessWidget {
  final OrderEntity order;

  const OwnerOrderDetailPage({super.key, required this.order});

  static MaterialPageRoute route(OrderEntity order) => MaterialPageRoute(
    builder: (context) => OwnerOrderDetailPage(order: order),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Pesanan',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppPallete.onPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: order.orderNumber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: 'Tanggal',
                  value: DatetimeFormatter.formatDateTime(order.createdAt),
                ),
                _InfoRow(label: 'Meja', value: '${order.tableNumber}'),
                _InfoRow(label: 'Pembayaran', value: order.payment.method),
                _InfoRow(label: 'Total Item', value: '${order.items.length}'),
                _InfoRow(
                  label: 'Total Pembayaran',
                  value: formatRupiah(order.total),
                  isHighlighted: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Ringkasan Pembayaran',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoRow(
                  label: 'Total Tagihan',
                  value: formatRupiah(order.payment.amountDue),
                ),
                _InfoRow(
                  label: 'Jumlah Bayar',
                  value: formatRupiah(order.payment.amountPaid),
                ),
                _InfoRow(
                  label: 'Kembalian',
                  value: formatRupiah(order.payment.changeGiven),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Item Pesanan (${order.items.length})',
            child: order.items.isEmpty
                ? Text(
                    'Item tidak ditemukan',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPallete.textPrimary,
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < order.items.length; i++)
                        _OrderItemTile(index: i + 1, item: order.items[i]),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPallete.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppPallete.primary,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlighted;

  const _InfoRow({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPallete.textPrimary),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
              color: isHighlighted
                  ? AppPallete.primary
                  : AppPallete.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final int index;
  final OrderItem item;

  const _OrderItemTile({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    final subtotal = item.quantity * item.unitPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPallete.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item $index',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppPallete.primary,
                ),
              ),
              Text(
                '${item.quantity} x ${formatRupiah(item.unitPrice)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppPallete.textPrimary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Nama Menu: ${item.menuName}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppPallete.textPrimary),
          ),
          if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Catatan: ${item.notes}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPallete.textPrimary),
            ),
          ],
          if (item.modifierSnapshot != null &&
              item.modifierSnapshot!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Tambahan: ${item.modifierSnapshot}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPallete.textPrimary),
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Subtotal: ${formatRupiah(subtotal)}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppPallete.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
