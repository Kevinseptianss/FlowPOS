import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/staff/presentation/bloc/staff_bloc.dart';

class AddStaffModal extends StatefulWidget {
  const AddStaffModal({super.key});

  @override
  State<AddStaffModal> createState() => _AddStaffModalState();
}

class _AddStaffModalState extends State<AddStaffModal> {
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool? _usernameExists;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      context.read<StaffBloc>().add(CreateStaffEvent(
            name: _nameController.text.trim(),
            username: _usernameController.text.trim().toLowerCase(),
            password: _passwordController.text,
          ));
    } else {
      // Small feedback for the user that validation failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon periksa kembali input Anda'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StaffBloc, StaffState>(
      listener: (context, state) {
        if (state is UsernameChecked) {
          setState(() => _usernameExists = state.exists);
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tambah Staff Baru',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppPallete.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Kasir akan login menggunakan Username & Password',
                style: GoogleFonts.outfit(color: AppPallete.textSecondary),
              ),
              const SizedBox(height: 32),
              _buildFieldTitle('Nama Lengkap'),
              TextFormField(
                controller: _nameController,
                style: GoogleFonts.outfit(),
                decoration: _buildInputDecoration('Contoh: Budi Santoso', Icons.person_rounded),
                validator: (v) => v == null || v.isEmpty ? 'Nama harus diisi' : null,
              ),
              const SizedBox(height: 20),
              _buildFieldTitle('Username'),
              TextFormField(
                controller: _usernameController,
                style: GoogleFonts.outfit(),
                onChanged: (v) {
                  if (v.isNotEmpty) {
                    context.read<StaffBloc>().add(CheckUsernameEvent(v.toLowerCase()));
                  } else {
                    setState(() => _usernameExists = null);
                  }
                },
                decoration: _buildInputDecoration(
                  'Contoh: budi_kasir',
                  Icons.alternate_email_rounded,
                  suffixIcon: _usernameExists == null
                      ? null
                      : Icon(
                          _usernameExists! ? Icons.close_rounded : Icons.check_circle_rounded,
                          color: _usernameExists! ? Colors.red : Colors.green,
                        ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Username harus diisi';
                  if (_usernameExists == true) return 'Username sudah digunakan';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildFieldTitle('Password'),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                style: GoogleFonts.outfit(),
                decoration: _buildInputDecoration('Min. 6 karakter', Icons.lock_rounded),
                validator: (v) => v == null || v.length < 6 ? 'Password minimal 6 karakter' : null,
              ),
              const SizedBox(height: 40),
              BlocBuilder<StaffBloc, StaffState>(
                builder: (context, state) {
                  final isLoading = state is StaffLoading;

                  return SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPallete.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        disabledBackgroundColor: AppPallete.primary.withAlpha(100),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Simpan Staff',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.bold,
          color: AppPallete.textPrimary,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon, {Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: AppPallete.primary, size: 20),
      suffixIcon: suffixIcon,
      hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppPallete.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }
}
