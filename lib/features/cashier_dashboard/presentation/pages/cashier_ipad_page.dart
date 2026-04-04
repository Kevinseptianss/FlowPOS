import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/services/cashier_shift_local_service.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_logout_dialog.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/cashier_shift_dialogs.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/list_menu_section.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/list_order_section.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/table_section.dart';
import 'package:flow_pos/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashierIpadPage extends StatefulWidget {
  const CashierIpadPage({super.key});

  @override
  State<CashierIpadPage> createState() => _CashierIpadPageState();
}

class _CashierIpadPageState extends State<CashierIpadPage> {
  late final CashierShiftLocalService _cashierShiftLocalService;

  bool _isShiftActive = false;
  bool _isShiftReady = false;
  bool _isProcessingShiftAction = false;
  String? _cashierId;

  @override
  void initState() {
    super.initState();
    _cashierShiftLocalService = serviceLocator<CashierShiftLocalService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapShiftState();
    });
  }

  Future<void> _bootstrapShiftState() async {
    final userState = context.read<UserBloc>().state;
    if (userState is! UserLoggedIn) {
      return;
    }

    _cashierId = userState.user.id;
    final hasActiveShift = _cashierShiftLocalService.hasActiveShift(
      userState.user.id,
    );

    if (hasActiveShift) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isShiftActive = true;
        _isShiftReady = true;
      });

      return;
    }

    final openingBalance = await showOpeningBalanceDialog(
      context,
      cashierName: userState.user.name,
    );

    await _cashierShiftLocalService.openShift(
      cashierId: userState.user.id,
      cashierName: userState.user.name,
      openingBalance: openingBalance,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isShiftActive = true;
      _isShiftReady = true;
    });

    showSnackbar(
      context,
      'Shift aktif. Modal awal tersimpan di local database.',
    );
  }

  Future<void> _closeShift() async {
    if (_cashierId == null || _isProcessingShiftAction) {
      return;
    }

    final activeShift = _cashierShiftLocalService.getActiveShift(_cashierId!);
    if (activeShift == null) {
      setState(() {
        _isShiftActive = false;
      });
      return;
    }

    final openingBalance =
        (activeShift['openingBalance'] as num?)?.toDouble() ?? 0;
    final openedAt = DateTime.tryParse(
      activeShift['openedAt'] as String? ?? '',
    );
    final confirmed = await showCloseShiftDialog(
      context,
      openingBalance: openingBalance,
      openedAt: openedAt ?? DateTime.now(),
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isProcessingShiftAction = true;
    });

    await _cashierShiftLocalService.closeShift(cashierId: _cashierId!);

    if (!mounted) {
      return;
    }

    setState(() {
      _isShiftActive = false;
      _isProcessingShiftAction = false;
    });

    showSnackbar(
      context,
      'Shift ditutup. Data tersimpan lokal dan siap dikirim ke database.',
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showLogoutDialog(
      context,
      accountLabel: 'cashier account',
    );

    if (!mounted || !shouldLogout) {
      return;
    }

    context.read<AuthBloc>().add(SignOutEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          showSnackbar(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          centerTitle: false,
          title: Row(
            children: [
              Text(
                'FlowPOS',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppPallete.onPrimary),
              ),
              const SizedBox(width: 16),
              BlocBuilder<UserBloc, UserState>(
                builder: (context, state) {
                  if (state is UserLoggedIn) {
                    return Text(
                      'Cashier: ${state.user.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppPallete.onPrimary,
                      ),
                    );
                  }

                  return const SizedBox();
                },
              ),
            ],
          ),
          actions: [
            if (!_isShiftReady)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppPallete.onPrimary,
                  ),
                ),
              )
            else if (_isShiftActive)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPallete.warning,
                    foregroundColor: AppPallete.onPrimary,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _isProcessingShiftAction ? null : _closeShift,
                  icon: const Icon(Icons.lock_clock_rounded),
                  label: const Text('Tutup Kasir'),
                ),
              )
            else
              IconButton(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                color: AppPallete.onPrimary,
                tooltip: 'Logout',
              ),
            const SizedBox(width: 8),
          ],
        ),
        body: Row(
          children: [
            Expanded(flex: 1, child: TableSection()),
            Expanded(flex: 2, child: ListMenuSection()),
            Expanded(flex: 1, child: ListOrderSection()),
          ],
        ),
      ),
    );
  }
}
