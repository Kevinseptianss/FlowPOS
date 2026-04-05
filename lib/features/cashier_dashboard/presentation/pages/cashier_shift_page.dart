import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/datetime_formatter.dart';
import 'package:flow_pos/core/utils/show_logout_dialog.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/services/cashier_shift_local_service.dart';
import 'package:flow_pos/features/auth/domain/entities/user.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flow_pos/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

class CashierShiftPage extends StatelessWidget {
  const CashierShiftPage({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final cashierShiftLocalService = serviceLocator<CashierShiftLocalService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Shift'), centerTitle: false),
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthFailure) {
            showSnackbar(context, state.message);
          } else if (state is AuthInitial) {
            Navigator.popUntil(context, (route) => route.isFirst);
          }
        },
        child: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is! UserLoggedIn) {
              return Center(
                child: Text(
                  'No authenticated cashier found.',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppPallete.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }

            final user = state.user;
            return StreamBuilder<BoxEvent>(
              stream: cashierShiftLocalService.watchActiveShift(user.id),
              builder: (context, snapshot) {
                final hasActiveShift = cashierShiftLocalService.hasActiveShift(
                  user.id,
                );

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 22),
                  children: [
                    _ProfileHero(user: user),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Current Shift',
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value: DatetimeFormatter.formatDateTime(now),
                          ),
                          _InfoRow(
                            icon: Icons.bolt_rounded,
                            label: 'Status',
                            value: hasActiveShift ? 'Open' : 'Closed',
                            valueColor: hasActiveShift
                                ? AppPallete.success
                                : AppPallete.warning,
                          ),
                          _InfoRow(
                            icon: Icons.badge_rounded,
                            label: 'Role',
                            value: user.role.toUpperCase(),
                          ),
                          _InfoRow(
                            icon: Icons.point_of_sale_rounded,
                            label: 'Terminal',
                            value: 'POS-01',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Profile Information',
                      child: Column(
                        children: [
                          _InfoRow(
                            icon: Icons.person_rounded,
                            label: 'Full Name',
                            value: user.name,
                          ),
                          _InfoRow(
                            icon: Icons.email_rounded,
                            label: 'Email',
                            value: user.email,
                          ),
                          _InfoRow(
                            icon: Icons.fingerprint_rounded,
                            label: 'User ID',
                            value: user.id,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () async {
                        final isShiftStillOpen = cashierShiftLocalService
                            .hasActiveShift(user.id);

                        if (isShiftStillOpen) {
                          showSnackbar(
                            context,
                            'Shift is still open. Please close your shift before logging out.',
                          );
                          return;
                        }

                        final shouldLogout = await showLogoutDialog(
                          context,
                          accountLabel: 'cashier account',
                        );

                        if (!context.mounted || !shouldLogout) {
                          return;
                        }

                        context.read<AuthBloc>().add(SignOutEvent());
                      },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPallete.error,
                        foregroundColor: AppPallete.onPrimary,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final User user;

  const _ProfileHero({required this.user});

  @override
  Widget build(BuildContext context) {
    final initials = _extractInitials(user.name);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPallete.primary, AppPallete.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(24),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withAlpha(40),
            child: Text(
              initials,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppPallete.onPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppPallete.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppPallete.onPrimary.withAlpha(225),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(36),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${user.role.toUpperCase()} SHIFT',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppPallete.onPrimary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.35,
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
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPallete.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppPallete.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppPallete.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppPallete.textPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: valueColor ?? AppPallete.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _extractInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) {
    return 'U';
  }

  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }

  final first = parts.first.substring(0, 1).toUpperCase();
  final last = parts.last.substring(0, 1).toUpperCase();
  return '$first$last';
}
