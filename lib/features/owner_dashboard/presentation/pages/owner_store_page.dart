import 'dart:ui';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_shift_history_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_staff_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_store_settings_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_payment_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OwnerStorePage extends StatelessWidget {
  const OwnerStorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // --- BACKGROUND ACCENT ---
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              color: AppPallete.primary.withAlpha(50),
              shape: BoxShape.circle,
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),

        SafeArea(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Manajemen Toko',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: AppPallete.textPrimary,
                        ),
                      ),
                      Text(
                        'Kelola profil, staff, dan operasional Anda',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: AppPallete.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
                SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 1,
                    mainAxisExtent: 160,
                    mainAxisSpacing: 20,
                  ),
                  delegate: SliverChildListDelegate([
                    _buildFeatureCard(
                      context,
                      title: 'Profil Toko',
                      subtitle: 'Nama, alamat, dan pajak restoran',
                      icon: Icons.storefront_rounded,
                      color: AppPallete.primary,
                      onTap: () => Navigator.push(context, OwnerStoreSettingsPage.route()),
                    ),
                    _buildFeatureCard(
                      context,
                      title: 'Metode Pembayaran',
                      subtitle: 'Cash, Card, Transfer, dan QRIS',
                      icon: Icons.payments_rounded,
                      color: Colors.teal,
                      onTap: () => Navigator.push(context, OwnerPaymentSettingsPage.route()),
                    ),
                    _buildFeatureCard(
                      context,
                      title: 'Manajemen Staff',
                      subtitle: 'Atur akun kasir dan hak akses',
                      icon: Icons.people_alt_rounded,
                      color: Colors.blue,
                      onTap: () => Navigator.push(context, OwnerStaffPage.route()),
                    ),
                    _buildFeatureCard(
                      context,
                      title: 'Riwayat Shift',
                      subtitle: 'Audit laporan buka-tutup kasir',
                      icon: Icons.history_toggle_off_rounded,
                      color: Colors.orange,
                      onTap: () => Navigator.push(context, OwnerShiftHistoryPage.route()),
                    ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppPallete.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: AppPallete.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, color: AppPallete.primary.withAlpha(100), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
