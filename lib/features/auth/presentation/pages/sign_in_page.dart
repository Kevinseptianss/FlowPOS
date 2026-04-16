import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flow_pos/features/auth/presentation/pages/sign_up_page.dart';
import 'package:flow_pos/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignInPage extends StatefulWidget {
  static MaterialPageRoute route() =>
      MaterialPageRoute(builder: (context) => const SignInPage());
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Gagal Masuk'),
                content: Text(state.message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 800) {
                return _TabletSignInLayout(
                  isLoading: isLoading,
                  emailController: _emailController,
                  passwordController: _passwordController,
                  formKey: _formKey,
                );
              }
              return _MobileSignInLayout(
                isLoading: isLoading,
                emailController: _emailController,
                passwordController: _passwordController,
                formKey: _formKey,
              );
            },
          );
        },
      ),
    );
  }
}

class _MobileSignInLayout extends StatelessWidget {
  final bool isLoading;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;

  const _MobileSignInLayout({
    required this.isLoading,
    required this.emailController,
    required this.passwordController,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const _BrandingHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: _SignInForm(
                isLoading: isLoading,
                emailController: emailController,
                passwordController: passwordController,
                formKey: formKey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabletSignInLayout extends StatelessWidget {
  final bool isLoading;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;

  const _TabletSignInLayout({
    required this.isLoading,
    required this.emailController,
    required this.passwordController,
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
        // Right Side: Login Form
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: _SignInForm(
                  isLoading: isLoading,
                  emailController: emailController,
                  passwordController: passwordController,
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
  const _BrandingHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
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
            'FlowPOS',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppPallete.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            'Masuk untuk melanjutkan operasional bisnis Anda.',
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
          // Background Image with Overlay
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
          // Content
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
                  'Kelola bisnis Anda dengan mudah, efisien, dan modern. Solusi kasir terbaik untuk pertumbuhan usaha Anda.',
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

class _SignInForm extends StatelessWidget {
  final bool isLoading;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;

  const _SignInForm({
    required this.isLoading,
    required this.emailController,
    required this.passwordController,
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
              'Masuk',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppPallete.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
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
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppPallete.secondary,
                  padding: EdgeInsets.zero,
                ),
                child: const Text('Lupa Kata Sandi?'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () {
                        if (formKey.currentState?.validate() ?? false) {
                          context.read<AuthBloc>().add(
                                SignInEvent(
                                  email: emailController.text,
                                  password: passwordController.text,
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
                child: isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Masuk',
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
                  'Belum punya akun?',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppPallete.textPrimary),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, SignUpPage.route());
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppPallete.secondary,
                  ),
                  child: const Text('Daftar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
