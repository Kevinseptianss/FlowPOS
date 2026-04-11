import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flutter/material.dart';

class IncomeCard extends StatelessWidget {
  final int qrisRevenue;
  final int cashRevenue;

  const IncomeCard({
    super.key,
    required this.qrisRevenue,
    required this.cashRevenue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Metode Pembayaran',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppPallete.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _PaymentMethodStat(
                  icon: Icons.qr_code_2_rounded,
                  label: 'QRIS',
                  value: formatRupiah(qrisRevenue),
                  color: Colors.blueAccent,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                margin: const EdgeInsets.symmetric(horizontal: 24),
                color: AppPallete.divider,
              ),
              Expanded(
                child: _PaymentMethodStat(
                  icon: Icons.payments_outlined,
                  label: 'Tunai',
                  value: formatRupiah(cashRevenue),
                  color: AppPallete.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _PaymentMethodStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppPallete.textSecondary,
                    ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppPallete.textPrimary,
                      ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
