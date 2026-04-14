import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/datetime_formatter.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OwnerOrderDetailPage extends StatelessWidget {
  final OrderEntity order;

  const OwnerOrderDetailPage({super.key, required this.order});

  static MaterialPageRoute route(OrderEntity order) => MaterialPageRoute(
    builder: (context) => OwnerOrderDetailPage(order: order),
  );

  @override
  Widget build(BuildContext context) {
    final isPaid = order.status == 'PAID';
    final statusColor = isPaid ? AppPallete.success : AppPallete.warning;
    final statusText = isPaid ? 'LUNAS' : 'MENUNGGU PEMBAYARAN';

    return Scaffold(
      backgroundColor: AppPallete.background,
      appBar: AppBar(
        title: Text(
          'Detail Transaksi',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppPallete.onPrimary),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppPallete.primary,
        iconTheme: const IconThemeData(color: AppPallete.onPrimary),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
          // Status Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: statusColor.withAlpha(50)),
            ),
            child: Column(
              children: [
                Icon(
                  isPaid ? Icons.check_circle_rounded : Icons.pending_actions_rounded,
                  color: statusColor,
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  statusText,
                  style: GoogleFonts.outfit(
                    color: statusColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPaid 
                    ? 'Transaksi selesai dan dibayar'
                    : 'Pesanan sedang diproses di meja',
                  style: GoogleFonts.outfit(
                    color: statusColor.withAlpha(180),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),

          // Order Metadata
          _buildInfoSection(context),

          const SizedBox(height: 24),

          // Item List Section
          Text(
            'Produk Pesanan',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppPallete.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) => _OrderItemTile(item: item)),
          
          const SizedBox(height: 24),

          // Financial Summary Section
          _buildFinancialSummary(context),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPallete.divider),
      ),
      child: Column(
        children: [
          _ModernInfoRow(
            icon: Icons.confirmation_number_outlined,
            label: 'No. Pesanan',
            value: order.orderNumber,
          ),
          const Divider(height: 32),
          _ModernInfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Waktu Transaksi',
            value: DatetimeFormatter.formatIndonesian(order.createdAt, includeTime: true),
          ),
          const Divider(height: 32),
          _ModernInfoRow(
            icon: Icons.table_restaurant_rounded,
            label: 'Nomor Meja',
            value: 'MEJA ${order.tableNumber}',
            valueColor: AppPallete.primary,
          ),
          const Divider(height: 32),
          _ModernInfoRow(
            icon: Icons.payments_outlined,
            label: 'Metode Pembayaran',
            value: order.payment?.method ?? '-',
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppPallete.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RINGKASAN TAGIHAN',
            style: GoogleFonts.outfit(
              color: AppPallete.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          _SummaryRow(label: 'Subtotal', value: formatRupiah(order.displaySubtotal)),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Pajak (Tax)', value: formatRupiah(order.displayTax)),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Service Charge', value: formatRupiah(order.displayServiceCharge)),
          const SizedBox(height: 12),
          _SummaryRow(label: 'Total Belanja', value: formatRupiah(order.total), isBold: true),
          if (order.payment != null) ...[
            const Divider(height: 32, thickness: 1),
            _SummaryRow(label: 'Jumlah Bayar', value: formatRupiah(order.payment!.amountPaid)),
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'Kembalian', 
              value: formatRupiah(order.payment!.changeGiven),
              isBold: true,
              valueColor: AppPallete.primary,
            ),
          ],
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppPallete.primary.withAlpha(10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppPallete.primary.withAlpha(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL AKHIR',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    color: AppPallete.primary,
                  ),
                ),
                Text(
                  formatRupiah(order.total),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: AppPallete.primary,
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

class _ModernInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final bool isBold;

  const _ModernInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppPallete.primary.withAlpha(15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppPallete.primary, size: 16),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.outfit(
                color: AppPallete.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: valueColor ?? AppPallete.textPrimary,
                fontSize: 14,
                fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;

  const _SummaryRow({
    required this.label, 
    required this.value, 
    this.isBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            color: AppPallete.textSecondary,
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            color: valueColor ?? AppPallete.textPrimary,
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _OrderItemTile extends StatelessWidget {
  final OrderItem item;

  const _OrderItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final subtotal = item.quantity * item.unitPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPallete.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppPallete.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${item.quantity}x',
                  style: GoogleFonts.outfit(
                    color: AppPallete.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.menuName,
                      style: GoogleFonts.outfit(
                        color: AppPallete.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatRupiah(item.unitPrice),
                      style: GoogleFonts.outfit(
                        color: AppPallete.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                formatRupiah(subtotal),
                style: GoogleFonts.outfit(
                  color: AppPallete.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          if (item.modifierSnapshot != null && item.modifierSnapshot!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppPallete.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline_rounded, size: 12, color: AppPallete.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.modifierSnapshot!,
                      style: GoogleFonts.outfit(
                        color: AppPallete.textSecondary,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.notes_rounded, size: 12, color: AppPallete.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.notes!,
                    style: GoogleFonts.outfit(
                      color: AppPallete.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
