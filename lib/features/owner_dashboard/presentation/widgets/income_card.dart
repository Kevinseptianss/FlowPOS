import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';

class IncomeCard extends StatelessWidget {
  final int qrisRevenue;
  final int cashRevenue;

  const IncomeCard({
    super.key,
    required this.qrisRevenue,
    required this.cashRevenue,
  });

  String _formatRupiahCompact(int value) {
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
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: AppPallete.surface,
      child: SizedBox(
        width: double.infinity,
        height: 80,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppPallete.background,
                        ),
                        child: Icon(
                          Icons.qr_code,
                          color: AppPallete.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'QRIS',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black),
                          ),
                          Text(
                            _formatRupiahCompact(qrisRevenue),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: double.infinity,
                color: AppPallete.divider,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppPallete.background,
                        ),
                        child: Icon(
                          Icons.money,
                          color: AppPallete.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cash',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.black),
                          ),
                          Text(
                            _formatRupiahCompact(cashRevenue),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
