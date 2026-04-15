import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flow_pos/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flow_pos/init_dependencies.dart';
import 'package:flow_pos/features/auth/domain/usecases/check_owner_exists.dart';
import 'package:flow_pos/core/usecase/use_case.dart';

class SignUpPage extends StatefulWidget {
  static MaterialPageRoute route() =>
      MaterialPageRoute(builder: (context) => const SignUpPage());
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _ownerExists = false;
  bool _isCheckingOwner = true;

  @override
  void initState() {
    super.initState();
    _checkOwnerStatus();
  }

  Future<void> _checkOwnerStatus() async {
    final result = await serviceLocator<CheckOwnerExists>().call(NoParams());
    result.fold(
      (failure) {
        if (mounted) {
          setState(() {
            _isCheckingOwner = false;
          });
        }
      },
      (exists) {
        if (mounted) {
          setState(() {
            _ownerExists = exists;
            _isCheckingOwner = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            showSnackbar(context, state.message);
          } else if (state is AuthSignUpSuccess) {
            showSnackbar(context, 'Akun berhasil dibuat! Silakan masuk.');
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          if (state is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    decoration: const BoxDecoration(
                      color: AppPallete.primary,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Buat Akun',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppPallete.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _ownerExists 
                            ? 'Akun Owner Sudah Terdaftar'
                            : 'Siapkan akun pemilik Anda dalam hitungan menit.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppPallete.onPrimary),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppPallete.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppPallete.divider),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daftar',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppPallete.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            AuthTextField(
                              controller: _nameController,
                              label: 'Nama',
                            ),
                            const SizedBox(height: 12),
                            AuthTextField(
                              controller: _emailController,
                              label: 'Email / Username',
                            ),
                            const SizedBox(height: 12),
                            AuthTextField(
                              controller: _passwordController,
                              label: 'Kata Sandi',
                              isPassword: true,
                            ),
                            const SizedBox(height: 12),
                            AuthTextField(
                              controller: _confirmPasswordController,
                              label: 'Konfirmasi Kata Sandi',
                              isPassword: true,
                              validator: (value) {
                                if (value != _passwordController.text) {
                                  return 'Kata sandi tidak cocok';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            if (_ownerExists)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'Aplikasi sudah memiliki Owner. Silakan hubungi Owner untuk mendapatkan akses sebagai Staff.',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            if (!_ownerExists)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isCheckingOwner ? null : () {
                                    if (_formKey.currentState?.validate() ??
                                        false) {
                                      context.read<AuthBloc>().add(
                                        SignUpEvent(
                                          name: _nameController.text,
                                          email: _emailController.text,
                                          password: _passwordController.text,
                                          role: 'owner',
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppPallete.primary,
                                    foregroundColor: AppPallete.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _isCheckingOwner 
                                    ? const SizedBox(
                                        height: 20, 
                                        width: 20, 
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                                      )
                                    : const Text('Buat Akun'),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Sudah punya akun?',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppPallete.textPrimary),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppPallete.secondary,
                                  ),
                                  child: const Text('Masuk'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
