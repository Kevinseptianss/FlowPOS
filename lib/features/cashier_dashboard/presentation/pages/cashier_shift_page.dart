import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/services/thermal_receipt_printer_service.dart';
import 'package:flow_pos/core/utils/datetime_formatter.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/core/utils/show_logout_dialog.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/services/cashier_shift_local_service.dart';
import 'package:flow_pos/features/auth/domain/entities/user.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:flow_pos/features/store_settings/presentation/bloc/store_settings_bloc.dart';
import 'package:flow_pos/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseClient;

class CashierShiftPage extends StatefulWidget {
  const CashierShiftPage({super.key});

  @override
  State<CashierShiftPage> createState() => _CashierShiftPageState();
}

class _CashierShiftPageState extends State<CashierShiftPage> {
  static const Duration _wibOffset = Duration(hours: 7);

  late final CashierShiftLocalService _cashierShiftLocalService;
  late final ThermalReceiptPrinterService _printerService;
  late final SupabaseClient _supabaseClient;

  String? _cachedCashierId;
  Future<_ClosedShiftReportData?>? _latestClosedShiftFuture;
  bool _isPrintingShiftReport = false;

  @override
  void initState() {
    super.initState();
    _cashierShiftLocalService = serviceLocator<CashierShiftLocalService>();
    _printerService = serviceLocator<ThermalReceiptPrinterService>();
    _supabaseClient = serviceLocator<SupabaseClient>();
  }

  void _ensureLatestClosedShiftFuture(String cashierId) {
    if (_cachedCashierId == cashierId && _latestClosedShiftFuture != null) {
      return;
    }

    _cachedCashierId = cashierId;
    _latestClosedShiftFuture = _fetchLatestClosedShift(cashierId: cashierId);
  }

  void _refreshLatestClosedShift(String cashierId) {
    setState(() {
      _cachedCashierId = cashierId;
      _latestClosedShiftFuture = _fetchLatestClosedShift(cashierId: cashierId);
    });
  }

  Future<_ClosedShiftReportData?> _fetchLatestClosedShift({
    required String cashierId,
  }) async {
    final shiftRows = await _supabaseClient
        .from('shifts')
        .select('''
          id,
          cashier_id,
          opened_at,
          closed_at,
          opening_balance,
          closing_balance,
          total_cash_sales,
          total_qris_sales,
          total_cash_in,
          total_cash_out
        ''')
        .eq('cashier_id', cashierId)
        .order('closed_at', ascending: false)
        .limit(1);

    if (shiftRows.isEmpty) {
      return null;
    }

    final shift = shiftRows.first;
    final openedAtUtc = DateTime.parse(shift['opened_at'] as String).toUtc();
    final closedAtUtc = DateTime.parse(shift['closed_at'] as String).toUtc();
    final openedAtWib = openedAtUtc.add(_wibOffset);
    final closedAtWib = closedAtUtc.add(_wibOffset);

    final orderRows = await _supabaseClient
        .from('orders')
        .select('id')
        .eq('cashier_id', cashierId)
        .gte('created_at', openedAtUtc.toIso8601String())
        .lte('created_at', closedAtUtc.toIso8601String());

    final totalTransactions = orderRows.length;
    final orderIds = orderRows
        .map((row) => row['id'] as String)
        .toList(growable: false);

    final soldByProduct = <String, int>{};
    if (orderIds.isNotEmpty) {
      final orderItemsRows = await _supabaseClient
          .from('order_items')
          .select('''
            quantity,
            menu_items (
              name
            )
          ''')
          .inFilter('order_id', orderIds);

      for (final row in orderItemsRows) {
        final quantity = (row['quantity'] as num?)?.toInt() ?? 0;
        final menuData = row['menu_items'];

        var menuName = 'Unknown Menu';
        if (menuData is Map<String, dynamic>) {
          menuName = menuData['name'] as String? ?? menuName;
        } else if (menuData is List && menuData.isNotEmpty) {
          final first = menuData.first;
          if (first is Map<String, dynamic>) {
            menuName = first['name'] as String? ?? menuName;
          }
        }

        soldByProduct.update(
          menuName,
          (value) => value + quantity,
          ifAbsent: () => quantity,
        );
      }
    }

    final soldProducts =
        soldByProduct.entries
            .map(
              (entry) =>
                  _SoldProductSummary(name: entry.key, quantity: entry.value),
            )
            .toList()
          ..sort((a, b) {
            final quantityCompare = b.quantity.compareTo(a.quantity);
            if (quantityCompare != 0) {
              return quantityCompare;
            }

            return a.name.compareTo(b.name);
          });

    return _ClosedShiftReportData(
      id: shift['id'] as String,
      cashierId: shift['cashier_id'] as String,
      openedAt: openedAtWib,
      closedAt: closedAtWib,
      openingBalance: (shift['opening_balance'] as num).toInt(),
      closingBalance: (shift['closing_balance'] as num).toInt(),
      totalCashSales: (shift['total_cash_sales'] as num).toInt(),
      totalQrisSales: (shift['total_qris_sales'] as num).toInt(),
      totalCashIn: (shift['total_cash_in'] as num).toInt(),
      totalCashOut: (shift['total_cash_out'] as num).toInt(),
      totalTransactions: totalTransactions,
      soldProducts: soldProducts,
    );
  }

  Future<void> _printClosedShiftReport({
    required User user,
    required _ClosedShiftReportData shift,
  }) async {
    setState(() {
      _isPrintingShiftReport = true;
    });

    try {
      final connected = await _printerService.isConnected;
      if (!connected) {
        final devices = await _printerService.getPairedDevices();
        if (devices.isEmpty) {
          throw Exception(
            'No paired printer found. Please pair your printer first.',
          );
        }

        if (!mounted) {
          return;
        }

        final selectedDevice = await _pickPrinterDevice(devices);
        if (selectedDevice == null) {
          return;
        }

        await _printerService.connect(macAddress: selectedDevice.macAddress);
      }

      await _printerService.printShiftCloseReport(
        storeSettings: _resolveStoreSettings(),
        cashierName: user.name,
        openedAt: shift.openedAt,
        closedAt: shift.closedAt,
        openingBalance: shift.openingBalance,
        closingBalance: shift.closingBalance,
        totalCashSales: shift.totalCashSales,
        totalQrisSales: shift.totalQrisSales,
        totalCashIn: shift.totalCashIn,
        totalCashOut: shift.totalCashOut,
        totalTransactions: shift.totalTransactions,
        soldProducts: shift.soldProducts
            .map(
              (item) => ShiftSoldProductSummary(
                name: item.name,
                quantity: item.quantity,
              ),
            )
            .toList(growable: false),
      );

      if (!mounted) {
        return;
      }

      showSnackbar(context, 'Laporan tutup kasir berhasil dicetak.');
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = error is Exception
          ? error.toString().replaceFirst('Exception: ', '')
          : 'Failed to print report.';
      showSnackbar(context, message);
    } finally {
      if (mounted) {
        setState(() {
          _isPrintingShiftReport = false;
        });
      }
    }
  }

  StoreSettings _resolveStoreSettings() {
    final state = context.read<StoreSettingsBloc>().state;

    if (state is StoreSettingsLoaded) {
      return state.storeSettings;
    }

    if (state is StoreSettingsUpdated) {
      return state.storeSettings;
    }

    return const StoreSettings.zero();
  }

  Future<PrinterDevice?> _pickPrinterDevice(List<PrinterDevice> devices) {
    return showModalBottomSheet<PrinterDevice>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppPallete.surface,
      builder: (modalContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Select Printer',
                  style: Theme.of(modalContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppPallete.textPrimary,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final device = devices[index];
                    return ListTile(
                      leading: const Icon(Icons.print_rounded),
                      title: Text(
                        device.name.isEmpty ? 'Unknown Printer' : device.name,
                      ),
                      subtitle: Text(device.macAddress),
                      onTap: () => Navigator.pop(modalContext, device),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final nowWib = DateTime.now().toUtc().add(_wibOffset);

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
            _ensureLatestClosedShiftFuture(user.id);

            return StreamBuilder<BoxEvent>(
              stream: _cashierShiftLocalService.watchActiveShift(user.id),
              builder: (context, snapshot) {
                final hasActiveShift = _cashierShiftLocalService.hasActiveShift(
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
                            value:
                                '${DatetimeFormatter.formatDateTime(nowWib)} WIB',
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
                    const SizedBox(height: 14),
                    _SectionCard(
                      title: 'Last Closed Shift (Database)',
                      trailing: IconButton(
                        onPressed: () => _refreshLatestClosedShift(user.id),
                        tooltip: 'Refresh',
                        icon: const Icon(Icons.refresh_rounded),
                        color: AppPallete.primary,
                      ),
                      child: FutureBuilder<_ClosedShiftReportData?>(
                        future: _latestClosedShiftFuture,
                        builder: (context, shiftSnapshot) {
                          if (shiftSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Center(child: CircularProgressIndicator()),
                            );
                          }

                          if (shiftSnapshot.hasError) {
                            return Text(
                              'Failed to load latest closed shift. Pull refresh and try again.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppPallete.error),
                            );
                          }

                          final closedShift = shiftSnapshot.data;
                          if (closedShift == null) {
                            return Text(
                              'No closed shift found in database for this cashier.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppPallete.textPrimary),
                            );
                          }

                          return Column(
                            children: [
                              _InfoRow(
                                icon: Icons.login_rounded,
                                label: 'Waktu Buka',
                                value: _formatShiftDateTime(
                                  closedShift.openedAt,
                                ),
                              ),
                              _InfoRow(
                                icon: Icons.logout_rounded,
                                label: 'Waktu Tutup',
                                value: _formatShiftDateTime(
                                  closedShift.closedAt,
                                ),
                              ),
                              _InfoRow(
                                icon: Icons.payments_rounded,
                                label: 'Modal Awal',
                                value: formatRupiah(closedShift.openingBalance),
                              ),
                              _InfoRow(
                                icon: Icons.attach_money_rounded,
                                label: 'CASH',
                                value: formatRupiah(closedShift.totalCashSales),
                              ),
                              _InfoRow(
                                icon: Icons.qr_code_rounded,
                                label: 'QRIS',
                                value: formatRupiah(closedShift.totalQrisSales),
                              ),
                              if (closedShift.totalCashIn > 0)
                                _InfoRow(
                                  icon: Icons.arrow_downward_rounded,
                                  label: 'Kas Masuk',
                                  value: formatRupiah(closedShift.totalCashIn),
                                ),
                              if (closedShift.totalCashOut > 0)
                                _InfoRow(
                                  icon: Icons.arrow_upward_rounded,
                                  label: 'Kas Keluar',
                                  value: formatRupiah(closedShift.totalCashOut),
                                ),
                              _InfoRow(
                                icon: Icons.summarize_rounded,
                                label: 'Total Penerimaan',
                                value: formatRupiah(
                                  closedShift.totalPenerimaan,
                                ),
                              ),
                              _InfoRow(
                                icon: Icons.account_balance_wallet_rounded,
                                label: 'Saldo Akhir',
                                value: formatRupiah(closedShift.saldoAkhir),
                              ),
                              _InfoRow(
                                icon: Icons.receipt_long_rounded,
                                label: 'Transaksi Masuk',
                                value: '${closedShift.totalTransactions}',
                              ),
                              const SizedBox(height: 10),
                              FilledButton.icon(
                                onPressed: _isPrintingShiftReport
                                    ? null
                                    : () => _printClosedShiftReport(
                                        user: user,
                                        shift: closedShift,
                                      ),
                                icon: _isPrintingShiftReport
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppPallete.onPrimary,
                                        ),
                                      )
                                    : const Icon(Icons.print_rounded),
                                label: Text(
                                  _isPrintingShiftReport
                                      ? 'Printing...'
                                      : 'Print Laporan Tutup Kasir',
                                ),
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46),
                                  backgroundColor: AppPallete.primary,
                                  foregroundColor: AppPallete.onPrimary,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () async {
                        final isShiftStillOpen = _cashierShiftLocalService
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
  final Widget trailing;

  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing = const SizedBox.shrink(),
  });

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
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppPallete.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ClosedShiftReportData {
  final String id;
  final String cashierId;
  final DateTime openedAt;
  final DateTime closedAt;
  final int openingBalance;
  final int closingBalance;
  final int totalCashSales;
  final int totalQrisSales;
  final int totalCashIn;
  final int totalCashOut;
  final int totalTransactions;
  final List<_SoldProductSummary> soldProducts;

  const _ClosedShiftReportData({
    required this.id,
    required this.cashierId,
    required this.openedAt,
    required this.closedAt,
    required this.openingBalance,
    required this.closingBalance,
    required this.totalCashSales,
    required this.totalQrisSales,
    required this.totalCashIn,
    required this.totalCashOut,
    required this.totalTransactions,
    required this.soldProducts,
  });

  int get totalPenerimaan => totalCashSales + totalQrisSales + totalCashIn;

  int get saldoAkhir => totalPenerimaan + openingBalance - closingBalance;
}

class _SoldProductSummary {
  final String name;
  final int quantity;

  const _SoldProductSummary({required this.name, required this.quantity});
}

String _formatShiftDateTime(DateTime value) {
  return '${DateFormat('dd MMM yyyy, HH:mm').format(value)} WIB';
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
