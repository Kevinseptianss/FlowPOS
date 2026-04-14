import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MenuItemCard extends StatelessWidget {
  final String name;
  final int price;
  final VoidCallback onQuickAdd;
  final VoidCallback onShowDetail;

  const MenuItemCard({
    super.key,
    required this.name,
    required this.price,
    required this.onQuickAdd,
    required this.onShowDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Main Content (Details Area)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onShowDetail,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppPallete.primary.withAlpha(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          name.length >= 2 ? name.substring(0, 2).toUpperCase() : name.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppPallete.primary.withAlpha(150),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppPallete.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            price == 0 ? 'Gratis' : formatRupiah(price),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppPallete.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Quick Add Button
            Positioned(
              right: 12,
              bottom: 12,
              child: Material(
                color: AppPallete.primary,
                borderRadius: BorderRadius.circular(16),
                elevation: 4,
                shadowColor: AppPallete.primary.withAlpha(100),
                child: InkWell(
                  onTap: onQuickAdd,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
