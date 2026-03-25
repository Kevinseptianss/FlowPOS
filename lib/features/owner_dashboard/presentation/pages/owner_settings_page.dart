import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OwnerSettingsPage extends StatelessWidget {
  static MaterialPageRoute route() =>
      MaterialPageRoute(builder: (context) => const OwnerSettingsPage());

  const OwnerSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppPallete.onPrimary),
        ),
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            showSnackbar(context, state.message);
          } else if (state is AuthInitial) {
            // User logged out, navigate back to sign in
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Account Settings',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppPallete.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: AppPallete.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppPallete.divider),
                ),
                child: ListTile(
                  leading: const Icon(Icons.logout, color: AppPallete.error),
                  title: Text(
                    'Logout',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyLarge?.copyWith(color: AppPallete.error),
                  ),
                  subtitle: Text(
                    'Sign out from your account',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPallete.textPrimary,
                    ),
                  ),
                  onTap: () {
                    // Show confirmation dialog
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirm Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                              context.read<AuthBloc>().add(SignOutEvent());
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: AppPallete.error,
                            ),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'More options will be added here',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPallete.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
