import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_logout_dialog.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/printer_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class CashierSettingsPage extends StatelessWidget {
  const CashierSettingsPage({super.key});

  Future<void> _logout(BuildContext context) async {
    final shouldLogout = await showLogoutDialog(
      context,
      accountLabel: 'cashier account',
    );

    if (!context.mounted || !shouldLogout) {
      return;
    }

    context.read<AuthBloc>().add(SignOutEvent());
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserBloc>().state;
    final name = userState is UserLoggedIn ? userState.user.name : 'Unknown';
    final email = userState is UserLoggedIn ? userState.user.email : '';

    return Scaffold(
      backgroundColor: AppPallete.background,
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            _buildProfileCard(name, email),

            const SizedBox(height: 32),

            Text(
              'Perangkat',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppPallete.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsItem(
              icon: Icons.print_rounded,
              title: 'Printer Nota',
              subtitle: 'Pengaturan bluetooth & lebar kertas',
              color: AppPallete.primary,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const PrinterSettingsPage()),
                );
              },
            ),

            const SizedBox(height: 32),
            Text(
              'Akun',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppPallete.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsItem(
              icon: Icons.logout_rounded,
              title: 'Keluar',
              subtitle: 'Keluar dari aplikasi',
              color: Colors.red,
              onTap: () => _logout(context),
            ),

            const SizedBox(height: 48),
            Center(
              child: Column(
                children: [
                   Text(
                    'FlowPOS v1.0.0',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppPallete.textSecondary.withAlpha(100),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Made with ❤️ for your business',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      color: AppPallete.textSecondary.withAlpha(80),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: AppPallete.primary.withAlpha(20),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppPallete.primary,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppPallete.textPrimary,
                  ),
                ),
                Text(
                  email,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: AppPallete.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppPallete.primary.withAlpha(30),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'KASIR',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppPallete.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppPallete.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppPallete.textPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppPallete.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppPallete.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
