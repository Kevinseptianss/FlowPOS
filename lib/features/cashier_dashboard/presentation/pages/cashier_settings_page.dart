import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_logout_dialog.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  Future<void> _resetDatabase(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reset Database?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('Ini akan menghapus semua riwayat pesanan, pembayaran, dan shift. Data produk dan kategori tidak akan dihapus.', style: GoogleFonts.outfit()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Batal', style: GoogleFonts.outfit())),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('RESET ALL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
        ],
      )
    );

    if (confirm != true) return;

    try {
      final supabase = Supabase.instance.client;
      // Note: This relies on RLS allowing delete or being disabled for these tables
      await supabase.from('order_items').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await supabase.from('payments').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await supabase.from('orders').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      await supabase.from('shifts').delete().neq('id', '00000000-0000-0000-0000-000000000000');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Database berhasil dikosongkan. Mohon restart aplikasi.'),
            backgroundColor: Colors.green,
          )
        );
      }
    } catch (e) {
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal (Kemungkinan RLS): $e'),
            backgroundColor: Colors.red,
          )
        );
      }
    }
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
            Container(
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
              context,
              icon: Icons.logout_rounded,
              title: 'Keluar',
              subtitle: 'Keluar dari aplikasi',
              color: Colors.red,
              onTap: () => _logout(context),
            ),

            const SizedBox(height: 24),
            Text(
              'Maintenance',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppPallete.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildSettingsItem(
              context,
              icon: Icons.auto_delete_rounded,
              title: 'Kosongkan Database',
              subtitle: 'Hapus semua pesanan & history (Hati-hati!)',
              color: Colors.orange,
              onTap: () => _resetDatabase(context),
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                'FlowPOS v1.0.0',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppPallete.textSecondary.withAlpha(100),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppPallete.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
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
            Icon(Icons.chevron_right_rounded, color: AppPallete.textSecondary),
          ],
        ),
      ),
    );
  }
}
