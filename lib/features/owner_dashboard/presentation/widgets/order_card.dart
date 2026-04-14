import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OrderCard extends StatelessWidget {
  final String orderId;
  final String paymentType;
  final String datetime;
  final int totalItems;
  final String totalPayment;
  final VoidCallback? onTap;

  const OrderCard({
    super.key,
    required this.orderId,
    required this.paymentType,
    required this.datetime,
    required this.totalItems,
    required this.totalPayment,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isQris = paymentType.toUpperCase() == 'QRIS';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPallete.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status/Payment Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (isQris ? Colors.blueAccent : AppPallete.success).withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isQris ? Icons.qr_code_2_rounded : Icons.payments_outlined,
                  color: isQris ? Colors.blueAccent : AppPallete.success,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Order Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      orderId,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppPallete.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$datetime • $totalItems item',
                      style: GoogleFonts.outfit(
                        color: AppPallete.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Price & Method
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    totalPayment,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: AppPallete.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isQris ? Colors.blueAccent : AppPallete.success).withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      paymentType,
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: isQris ? Colors.blueAccent : AppPallete.success,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
