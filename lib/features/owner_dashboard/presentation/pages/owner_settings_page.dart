import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_logout_dialog.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_modifier_group_create_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_store_profile_settings_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_store_settings_page.dart';
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
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppPallete.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Sign out from your account',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPallete.textPrimary,
                    ),
                  ),
                  onTap: () async {
                    final shouldLogout = await showLogoutDialog(
                      context,
                      accountLabel: 'owner account',
                    );

                    if (!context.mounted || !shouldLogout) {
                      return;
                    }

                    context.read<AuthBloc>().add(SignOutEvent());
                  },
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Menu Configuration',
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
                  leading: const Icon(
                    Icons.tune_outlined,
                    color: AppPallete.primary,
                  ),
                  title: Text(
                    'Add Modifier Group',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppPallete.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Create a modifier group and its modifier options',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPallete.textPrimary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      OwnerModifierGroupCreatePage.route(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Store Configuration',
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
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(
                    Icons.storefront_outlined,
                    color: AppPallete.primary,
                  ),
                  title: Text(
                    'Store Profile',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppPallete.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Edit restaurant name and address',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPallete.textPrimary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      OwnerStoreProfileSettingsPage.route(),
                    );
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: AppPallete.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppPallete.divider),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.receipt_long_outlined,
                    color: AppPallete.primary,
                  ),
                  title: Text(
                    'Tax & Service Charge',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppPallete.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Configure checkout tax and service percentages',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPallete.textPrimary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(context, OwnerStoreSettingsPage.route());
                  },
                ),
              ),
              const SizedBox(height: 24),
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
