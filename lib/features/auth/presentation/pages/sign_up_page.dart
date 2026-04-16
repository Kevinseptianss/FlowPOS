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
          final isLoading = state is AuthLoading;

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return _TabletSignUpLayout(
                  isLoading: isLoading,
                  isCheckingOwner: _isCheckingOwner,
                  ownerExists: _ownerExists,
                  nameController: _nameController,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  confirmPasswordController: _confirmPasswordController,
                  formKey: _formKey,
                );
              }
              return _MobileSignUpLayout(
                isLoading: isLoading,
                isCheckingOwner: _isCheckingOwner,
                ownerExists: _ownerExists,
                nameController: _nameController,
                emailController: _emailController,
                passwordController: _passwordController,
                confirmPasswordController: _confirmPasswordController,
                formKey: _formKey,
              );
            },
          );
        },
      ),
    );
  }
}

class _MobileSignUpLayout extends StatelessWidget {
  final bool isLoading;
  final bool isCheckingOwner;
  final bool ownerExists;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;

  const _MobileSignUpLayout({
    required this.isLoading,
    required this.isCheckingOwner,
    required this.ownerExists,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            _BrandingHeader(ownerExists: ownerExists),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: _SignUpForm(
                isLoading: isLoading,
                isCheckingOwner: isCheckingOwner,
                ownerExists: ownerExists,
                nameController: nameController,
                emailController: emailController,
                passwordController: passwordController,
                confirmPasswordController: confirmPasswordController,
                formKey: formKey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabletSignUpLayout extends StatelessWidget {
  final bool isLoading;
  final bool isCheckingOwner;
  final bool ownerExists;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;

  const _TabletSignUpLayout({
    required this.isLoading,
    required this.isCheckingOwner,
    required this.ownerExists,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left Side: Branding Hero
        const Expanded(
          child: _BrandingHeroSection(),
        ),
        // Right Side: SignUp Form
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: _SignUpForm(
                  isLoading: isLoading,
                  isCheckingOwner: isCheckingOwner,
                  ownerExists: ownerExists,
                  nameController: nameController,
                  emailController: emailController,
                  passwordController: passwordController,
                  confirmPasswordController: confirmPasswordController,
                  formKey: formKey,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrandingHeader extends StatelessWidget {
  final bool ownerExists;
  const _BrandingHeader({required this.ownerExists});

  @override
  Widget build(BuildContext context) {
    return Container(
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppPallete.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            ownerExists ? 'Akun Owner Sudah Terdaftar' : 'Siapkan akun pemilik Anda dalam hitungan menit.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppPallete.onPrimary),
          ),
        ],
      ),
    );
  }
}

class _BrandingHeroSection extends StatelessWidget {
  const _BrandingHeroSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppPallete.primary,
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/login_hero.png',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppPallete.primary.withAlpha(200),
                  Colors.transparent,
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'FlowPOS',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Solusi Point of Sale modern untuk bisnis masa depan. Daftar sekarang dan mulai transformasi operasional Anda.',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white.withAlpha(230),
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignUpForm extends StatelessWidget {
  final bool isLoading;
  final bool isCheckingOwner;
  final bool ownerExists;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final GlobalKey<FormState> formKey;

  const _SignUpForm({
    required this.isLoading,
    required this.isCheckingOwner,
    required this.ownerExists,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPallete.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Daftar',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppPallete.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            AuthTextField(
              controller: nameController,
              label: 'Nama',
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: emailController,
              label: 'Email / Username',
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: passwordController,
              label: 'Kata Sandi',
              isPassword: true,
            ),
            const SizedBox(height: 16),
            AuthTextField(
              controller: confirmPasswordController,
              label: 'Konfirmasi Kata Sandi',
              isPassword: true,
              validator: (value) {
                if (value != passwordController.text) {
                  return 'Kata sandi tidak cocok';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (ownerExists)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
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
            if (!ownerExists)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (isCheckingOwner || isLoading)
                      ? null
                      : () {
                          if (formKey.currentState?.validate() ?? false) {
                            context.read<AuthBloc>().add(
                                  SignUpEvent(
                                    name: nameController.text,
                                    email: emailController.text,
                                    password: passwordController.text,
                                    role: 'owner',
                                  ),
                                );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPallete.primary,
                    foregroundColor: AppPallete.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: (isCheckingOwner || isLoading)
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Buat Akun',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sudah punya akun?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppPallete.textPrimary),
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
    );
  }
}
