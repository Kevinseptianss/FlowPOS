import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
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
            showSnackbar(context, state.message);
          } else if (state is AuthSuccess) {
            Navigator.popUntil(context, (route) => route.isFirst);
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: AppPallete.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sign in to continue your business operations.',
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
                              'Sign In',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: AppPallete.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 16),
                            AuthTextField(
                              controller: _emailController,
                              label: 'Email',
                            ),
                            const SizedBox(height: 12),
                            AuthTextField(
                              controller: _passwordController,
                              label: 'Password',
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
                                child: const Text('Forgot Password?'),
                              ),
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    context.read<AuthBloc>().add(
                                      SignInEvent(
                                        email: _emailController.text,
                                        password: _passwordController.text,
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
                                child: const Text('Sign In'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Don\'t have an account?',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: AppPallete.textPrimary),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      SignUpPage.route(),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppPallete.secondary,
                                  ),
                                  child: const Text('Sign Up'),
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
