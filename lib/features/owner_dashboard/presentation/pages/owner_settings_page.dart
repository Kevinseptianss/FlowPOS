import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_logout_dialog.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class OwnerSettingsPage extends StatelessWidget {
  const OwnerSettingsPage({super.key});

  void _showChangePasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthPasswordChangedSuccess) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.white),
                    const SizedBox(width: 12),
                    Text('Kata sandi diperbarui!', style: GoogleFonts.outfit()),
                  ],
                ),
                backgroundColor: Colors.green.shade600,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.all(20),
              ),
            );
            context.read<AuthBloc>().add(SignOutEvent());
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message, style: GoogleFonts.outfit()),
                backgroundColor: AppPallete.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        },
        child: StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppPallete.background,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(20),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Section
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppPallete.primary.withAlpha(10),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppPallete.primary.withAlpha(30),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.lock_reset_rounded,
                                size: 40,
                                color: AppPallete.primary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ubah Kata Sandi',
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppPallete.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'Gunakan kata sandi yang kuat untuk menjaga keamanan akun Anda',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: AppPallete.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Form Section
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Form(
                          key: formKey,
                          child: Column(
                            children: [
                              _buildModernTextField(
                                controller: passwordController,
                                label: 'Kata Sandi Baru',
                                icon: Icons.vpn_key_rounded,
                                obscureText: obscurePassword,
                                onToggle: () => setState(() => obscurePassword = !obscurePassword),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Wajib diisi';
                                  if (value.length < 6) return 'Minimal 6 karakter';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildModernTextField(
                                controller: confirmPasswordController,
                                label: 'Konfirmasi Kata Sandi',
                                icon: Icons.verified_user_rounded,
                                obscureText: obscureConfirm,
                                onToggle: () => setState(() => obscureConfirm = !obscureConfirm),
                                validator: (value) {
                                  if (value != passwordController.text) return 'Kata sandi tidak cocok';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 40),
                              
                              // Buttons
                              Row(
                                children: [
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: Text(
                                        'Batal',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w600,
                                          color: AppPallete.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (formKey.currentState!.validate()) {
                                          context.read<AuthBloc>().add(
                                                AuthChangePasswordEvent(newPassword: passwordController.text.trim()),
                                              );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppPallete.primary,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        elevation: 8,
                                        shadowColor: AppPallete.primary.withAlpha(100),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: BlocBuilder<AuthBloc, AuthState>(
                                        builder: (context, state) {
                                          if (state is AuthLoading) {
                                            return const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                            );
                                          }
                                          return Text(
                                            'Simpan',
                                            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                                          );
                                        },
                                      ),
                                    ),
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
          },
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool obscureText,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppPallete.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Masukkan $label',
            hintStyle: GoogleFonts.outfit(fontSize: 14, color: AppPallete.textSecondary.withAlpha(100)),
            prefixIcon: Icon(icon, color: AppPallete.primary, size: 20),
            suffixIcon: IconButton(
              icon: Icon(obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded, 
                  color: AppPallete.textSecondary, size: 20),
              onPressed: onToggle,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppPallete.divider),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: AppPallete.divider),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppPallete.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppPallete.error, width: 1),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          showSnackbar(context, state.message);
        } else if (state is AuthInitial) {
          Navigator.popUntil(context, (route) => route.isFirst);
        } else if (state is AuthPasswordChangedSuccess) {
           ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Kata sandi berhasil diubah! Silahkan login kembali.'),
                backgroundColor: Colors.green,
              ),
            );
            context.read<AuthBloc>().add(SignOutEvent());
        }
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pengaturan',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppPallete.textPrimary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Kelola akun dan konfigurasi toko Anda',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppPallete.textSecondary,
                  ),
            ),
            const SizedBox(height: 40),

            _buildSectionHeader(context, 'Keamanan'),
            _buildSettingCard(
              context,
              icon: Icons.lock_outline_rounded,
              title: 'Ubah Kata Sandi',
              subtitle: 'Perbarui kata sandi admin Anda',
              iconColor: Colors.blueGrey,
              onTap: () => _showChangePasswordDialog(context),
            ),

            const SizedBox(height: 32),
            _buildSectionHeader(context, 'Akun'),
            _buildSettingCard(
              context,
              icon: Icons.logout_rounded,
              title: 'Keluar',
              subtitle: 'Keluar dari akun pemilik saat ini',
              color: AppPallete.error,
              onTap: () async {
                final shouldLogout = await showLogoutDialog(
                  context,
                  accountLabel: 'akun pemilik',
                );
                if (shouldLogout && context.mounted) {
                  context.read<AuthBloc>().add(SignOutEvent());
                }
              },
            ),

            // Only Akun section remains here
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppPallete.textSecondary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
      ),
    );
  }

  Widget _buildSettingCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
  }) {
    final titleColor = color ?? AppPallete.textPrimary;
    final primaryIconColor = color ?? iconColor ?? AppPallete.primary;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryIconColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: primaryIconColor, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppPallete.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppPallete.textSecondary.withAlpha(100),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
