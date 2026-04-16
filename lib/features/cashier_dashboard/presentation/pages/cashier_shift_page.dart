import 'dart:async';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/currency_input_formatter.dart';
import 'package:flow_pos/core/utils/datetime_formatter.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/services/cashier_shift_local_service.dart';
import 'package:flow_pos/features/auth/domain/entities/user.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:flow_pos/features/shift/presentation/bloc/shift_bloc.dart';
import 'package:flow_pos/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flow_pos/features/expense/presentation/bloc/expense_bloc.dart';
import 'package:flow_pos/features/expense/domain/entities/expense_entity.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/cash_action_dialog.dart';

class CashierShiftPage extends StatefulWidget {
  const CashierShiftPage({super.key});

  @override
  State<CashierShiftPage> createState() => _CashierShiftPageState();
}

class _CashierShiftPageState extends State<CashierShiftPage> {
  late final CashierShiftLocalService _cashierShiftLocalService;
  late final FirebaseFirestore _firestore;

  String? _cachedCashierId;
  String? _cachedShiftId;
  Future<_CurrentShiftStats?>? _currentShiftStatsFuture;
  Timer? _durationTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cashierShiftLocalService = serviceLocator<CashierShiftLocalService>();
    _firestore = serviceLocator<FirebaseFirestore>();

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    super.dispose();
  }

  void _ensureDataLoaded(String cashierId, String? shiftId) {
    if (_cachedCashierId == cashierId && _cachedShiftId == shiftId && _currentShiftStatsFuture != null) {
      return;
    }

    _cachedCashierId = cashierId;
    _cachedShiftId = shiftId;
    
    // Initialize the future directly without setState because this is called during build
    if (shiftId != null) {
      _currentShiftStatsFuture = _fetchCurrentShiftStats(
        cashierId: cashierId,
        shiftId: shiftId,
      );
    } else {
      _currentShiftStatsFuture = null;
    }
  }

  void _refreshAll(String cashierId, String? shiftId) {
    setState(() {
      _cachedCashierId = cashierId;
      _cachedShiftId = shiftId;
      _refreshCurrentShiftStats(cashierId, shiftId);
    });
  }

  void _refreshCurrentShiftStats(String cashierId, String? shiftId) {
    if (shiftId != null) {
      setState(() {
        _currentShiftStatsFuture = _fetchCurrentShiftStats(
          cashierId: cashierId,
          shiftId: shiftId,
        );
      });
    } else {
      setState(() {
        _currentShiftStatsFuture = null;
      });
    }
  }

  Future<_CurrentShiftStats?> _fetchCurrentShiftStats({
    required String cashierId,
    required String shiftId,
  }) async {
    try {
      final orderSnapshot = await _firestore
          .collection('orders')
          .where('shift_id', isEqualTo: shiftId)
          .get();

      var totalCashSales = 0;
      var totalQrisSales = 0;
      var totalTransactions = 0;
      final soldByProduct = <String, int>{};

      for (final doc in orderSnapshot.docs) {
        final data = doc.data();
        if (data['status'] == 'VOIDED') continue;
        
        totalTransactions++;

        final payment = data['payment'] as Map<String, dynamic>?;
        if (payment != null) {
          final method = (payment['method'] as String? ?? '').trim().toUpperCase();
          final amountPaid = (payment['amount_due'] as num?)?.toInt() ?? 0;

          if (method == 'QRIS') {
            totalQrisSales += amountPaid;
          } else if (method == 'CASH') {
            totalCashSales += amountPaid;
          }
        }

        final itemsData = data['items'] as List<dynamic>? ?? [];
        for (final item in itemsData) {
          if (item['is_deleted'] == true) continue;
          
          final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
          final menuName = item['menu_name'] as String? ?? 'Produk Tidak Dikenal';

          soldByProduct.update(
            menuName,
            (value) => value + quantity,
            ifAbsent: () => quantity,
          );
        }
      }

      final soldProducts = soldByProduct.entries
          .map((e) => _SoldProductSummary(name: e.key, quantity: e.value))
          .toList()
        ..sort((a, b) => b.quantity.compareTo(a.quantity));

      // Fetch expenses for this shift
      final expenseSnapshot = await _firestore
          .collection('expenses')
          .where('shift_id', isEqualTo: shiftId)
          .orderBy('created_at', descending: true)
          .get();

      final expenses = expenseSnapshot.docs.map((doc) {
        final d = doc.data();
        return ExpenseEntity(
          id: doc.id,
          amount: (d['amount'] as num).toInt(),
          categoryId: d['category_id'] as String,
          categoryName: d['category_name'] as String,
          note: d['note'] as String,
          type: d['type'] as String,
          cashActionType: d['cash_action_type'] as String,
          staffId: d['staff_id'] as String,
          staffName: d['staff_name'] as String,
          shiftId: d['shift_id'] as String?,
          createdAt: (d['created_at'] as Timestamp).toDate(),
          isAdjustment: d['is_adjustment'] as bool? ?? false,
        );
      }).toList();

      var totalCashIn = 0;
      var totalCashOut = 0;
      for (final ex in expenses) {
        if (ex.cashActionType == 'CASH_IN') totalCashIn += ex.amount;
        if (ex.cashActionType == 'CASH_OUT') totalCashOut += ex.amount;
      }

      return _CurrentShiftStats(
        totalCashSales: totalCashSales,
        totalQrisSales: totalQrisSales,
        totalTransactions: totalTransactions,
        soldProducts: soldProducts,
        totalCashIn: totalCashIn,
        totalCashOut: totalCashOut,
        expenses: expenses,
      );
    } catch (e) {
      debugPrint('Error fetching active shift stats: $e');
      return null;
    }
  }

  String _formatDuration(DateTime openedAt) {
    final diff = _now.difference(openedAt);
    final hours = diff.inHours.toString().padLeft(2, '0');
    final minutes = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> _showCloseShiftDialog(BuildContext context, String cashierId, int expectedCash) async {
    final initialText = formatRupiah(expectedCash, includeSymbol: false);
    final controller = TextEditingController(text: initialText);
    
    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppPallete.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 40, offset: const Offset(0, 10)),
          ],
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
          left: 28,
          right: 28,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(color: AppPallete.divider, borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppPallete.error.withAlpha(20), shape: BoxShape.circle),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppPallete.error, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selesaikan Shift', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w900, color: AppPallete.textPrimary, letterSpacing: -0.5)),
                      Text('Pastikan jumlah uang tunai sudah sesuai', style: GoogleFonts.outfit(fontSize: 13, color: AppPallete.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppPallete.background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppPallete.divider),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Estimasi Sistem', style: GoogleFonts.outfit(color: AppPallete.textSecondary, fontWeight: FontWeight.w600)),
                      Text(formatRupiah(expectedCash), style: GoogleFonts.outfit(color: AppPallete.primary, fontWeight: FontWeight.w900, fontSize: 16)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  Text(
                    'Masukkan jumlah uang tunai yang ada di laci kasir saat ini:',
                    style: GoogleFonts.outfit(fontSize: 12, color: AppPallete.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [
                CurrencyInputFormatter(),
              ],
              autofocus: true,
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppPallete.textPrimary),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppPallete.textSecondary),
                hintText: '0',
                filled: true,
                fillColor: AppPallete.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text('Nanti Dulu', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppPallete.textSecondary)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: () {
                      final plainText = controller.text.replaceAll(RegExp(r'[^0-9]'), '');
                      Navigator.pop(context, double.tryParse(plainText) ?? 0.0);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPallete.error,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                      shadowColor: AppPallete.error.withAlpha(100),
                    ),
                    child: Text('TUTUP SHIFT', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (result != null && result > 0 && context.mounted) {
      context.read<ShiftBloc>().add(CloseShiftEvent(
        cashierId: cashierId,
        closingBalance: result,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserBloc>().state;
    if (userState is! UserLoggedIn) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final userId = userState.user.id;

    return Scaffold(
      backgroundColor: AppPallete.background,
      appBar: AppBar(
        title: Text('Shift Kasir', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppPallete.textPrimary,
        centerTitle: false,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<ShiftBloc, ShiftState>(
            listener: (context, state) {
              if (state is ShiftOpened) {
                _ensureDataLoaded(userId, state.shift.id);
              } else if (state is ShiftClosed) {
                showSnackbar(context, 'Shift berhasil ditutup');
                setState(() {
                  _cachedShiftId = null;
                  _currentShiftStatsFuture = null;
                });
                // Automatically logout after closing shift
                context.read<AuthBloc>().add(SignOutEvent());
              } else if (state is ShiftFailure) {
                showSnackbar(context, state.message);
              }
            },
          ),
          BlocListener<OrderBloc, OrderState>(
            listener: (context, state) {
              if (state is OrderCreated) {
                // Auto refresh when a new order is made
                final activeShift = _cashierShiftLocalService.getActiveShift(userId);
                final shiftId = activeShift?['shiftId'] as String?;
                if (shiftId != null) {
                  _refreshCurrentShiftStats(userId, shiftId);
                }
              }
            },
          ),
          BlocListener<ExpenseBloc, ExpenseState>(
            listener: (context, state) {
              if (state is ExpenseCreated) {
                final activeShift = _cashierShiftLocalService.getActiveShift(userId);
                final shiftId = activeShift?['shiftId'] as String?;
                if (shiftId != null) {
                  _refreshCurrentShiftStats(userId, shiftId);
                }
              }
            },
          ),
        ],
        child: BlocBuilder<UserBloc, UserState>(
          builder: (context, state) {
            if (state is! UserLoggedIn) return const Center(child: CircularProgressIndicator());
            
            final user = state.user;
            final activeShift = _cashierShiftLocalService.getActiveShift(user.id);
            final shiftId = activeShift?['shiftId'] as String?;
            
            _ensureDataLoaded(user.id, shiftId);

            return RefreshIndicator(
              onRefresh: () async => _refreshAll(user.id, shiftId),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  _ProfileHero(user: user),
                  const SizedBox(height: 24),
                  
                  if (activeShift != null) ...[
                    _ActiveShiftHero(
                      openedAt: DateTime.parse(activeShift['openedAtUtc'] as String).toLocal(),
                      openingBalance: (activeShift['openingBalance'] as num).toInt(),
                      duration: _formatDuration(DateTime.parse(activeShift['openedAtUtc'] as String).toLocal()),
                      statsFuture: _currentShiftStatsFuture,
                      onCloseShift: (expected) => _showCloseShiftDialog(context, user.id, expected),
                      staffId: user.id,
                      staffName: user.name,
                      shiftId: shiftId!,
                    ),
                  ] else
                    _NoActiveShiftCard(),

                  const SizedBox(height: 100),
                ],
              ),
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPallete.divider),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AppPallete.primary.withAlpha(30),
            child: Text(
              user.name.substring(0, 1).toUpperCase(),
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: AppPallete.primary),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.name, style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppPallete.textPrimary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 12, color: AppPallete.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      DatetimeFormatter.formatDateYear(DateTime.now()),
                      style: GoogleFonts.outfit(fontSize: 12, color: AppPallete.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppPallete.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              user.role.toUpperCase(),
              style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActiveShiftHero extends StatelessWidget {
  final DateTime openedAt;
  final int openingBalance;
  final String duration;
  final Future<_CurrentShiftStats?>? statsFuture;
  final Function(int expectedCash) onCloseShift;

  final String staffId;
  final String staffName;
  final String shiftId;

  const _ActiveShiftHero({
    required this.openedAt,
    required this.openingBalance,
    required this.duration,
    required this.statsFuture,
    required this.onCloseShift,
    required this.staffId,
    required this.staffName,
    required this.shiftId,
  });

  void _showCashActionDialog(BuildContext context, String type) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Cash Action',
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: animation,
            child: CashActionDialog(
              staffId: staffId,
              staffName: staffName,
              shiftId: shiftId,
            ),
          ),
        );
      },
    );

    if (result == true) {
      // Refresh will be handled by BlocListener in parent
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_CurrentShiftStats?>(
      future: statsFuture,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final cashSales = stats?.totalCashSales ?? 0;
        final cashIn = stats?.totalCashIn ?? 0;
        final cashOut = stats?.totalCashOut ?? 0;
        final expectedCash = openingBalance + cashSales + cashIn - cashOut;

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppPallete.primary, AppPallete.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: AppPallete.primary.withAlpha(60), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('DURASI KERJA', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                          const SizedBox(height: 4),
                          Text(duration, style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.timer_rounded, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(height: 1, color: Colors.white12),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ShiftStatMini(label: 'UANG TUNAI DIHARAPKAN', value: formatRupiah(expectedCash)),
                      _ShiftStatMini(label: 'SALDO AWAL', value: formatRupiah(openingBalance)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _ShiftStatMini(label: 'TOTAL KAS MASUK (+)', value: formatRupiah(stats?.totalCashIn ?? 0), color: Colors.greenAccent),
                      _ShiftStatMini(label: 'TOTAL KAS KELUAR (-)', value: formatRupiah(stats?.totalCashOut ?? 0), color: Colors.redAccent),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _CashActionButton(
                    label: 'Kas Masuk',
                    icon: Icons.add_circle_outline_rounded,
                    color: AppPallete.success,
                    onTap: () => _showCashActionDialog(context, 'CASH_IN'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CashActionButton(
                    label: 'Kas Keluar',
                    icon: Icons.remove_circle_outline_rounded,
                    color: AppPallete.error,
                    onTap: () => _showCashActionDialog(context, 'CASH_OUT'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _StatsGrid(stats: stats),
            const SizedBox(height: 16),
            _CashLedgerSection(expenses: stats?.expenses ?? []),
            const SizedBox(height: 16),
            _SoldItemsSection(soldItems: stats?.soldProducts ?? []),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => onCloseShift(expectedCash),
                icon: const Icon(Icons.logout_rounded),
                label: Text('TUTUP SHIFT', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppPallete.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  elevation: 4,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ShiftStatMini extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _ShiftStatMini({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white60, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        Text(value, style: GoogleFonts.outfit(color: color ?? Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final _CurrentShiftStats? stats;
  const _StatsGrid({this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'Transaksi', value: '${stats?.totalTransactions ?? 0}', icon: Icons.receipt_long_rounded, color: AppPallete.primary)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'QRIS', value: formatRupiah(stats?.totalQrisSales ?? 0), icon: Icons.qr_code_rounded, color: Colors.orange)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppPallete.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppPallete.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 12),
          Text(label, style: GoogleFonts.outfit(color: AppPallete.textSecondary, fontSize: 12)),
          FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: GoogleFonts.outfit(color: AppPallete.textPrimary, fontSize: 18, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}

class _SoldItemsSection extends StatelessWidget {
  final List<_SoldProductSummary> soldItems;
  const _SoldItemsSection({required this.soldItems});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppPallete.surface, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppPallete.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Item Terjual', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppPallete.textPrimary)),
              const Icon(Icons.shopping_bag_outlined, size: 20, color: AppPallete.textSecondary),
            ],
          ),
          const SizedBox(height: 20),
          if (soldItems.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, color: AppPallete.divider, size: 40),
                    const SizedBox(height: 8),
                    Text('Belum ada item terjual.', style: GoogleFonts.outfit(fontSize: 13, color: AppPallete.textSecondary)),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: soldItems.length,
              separatorBuilder: (_, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final item = soldItems[index];
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(item.name, style: GoogleFonts.outfit(color: AppPallete.textPrimary, fontWeight: FontWeight.w600))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: AppPallete.primary.withAlpha(20), borderRadius: BorderRadius.circular(10)),
                      child: Text('x${item.quantity}', style: GoogleFonts.outfit(color: AppPallete.primary, fontWeight: FontWeight.w900, fontSize: 13)),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _CashActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CashActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withAlpha(15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(50), width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CashLedgerSection extends StatelessWidget {
  final List<ExpenseEntity> expenses;
  const _CashLedgerSection({required this.expenses});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPallete.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Buku Kas (Ledger)', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppPallete.textPrimary)),
              Icon(Icons.history_rounded, size: 20, color: AppPallete.textSecondary),
            ],
          ),
          const SizedBox(height: 20),
          if (expenses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('Belum ada transaksi kas.', style: GoogleFonts.outfit(fontSize: 13, color: AppPallete.textSecondary)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              separatorBuilder: (_, __) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final ex = expenses[index];
                final isOut = ex.cashActionType == 'CASH_OUT';
                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isOut ? AppPallete.error : AppPallete.success).withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOut ? Icons.arrow_outward_rounded : Icons.arrow_back_rounded,
                        color: (isOut ? AppPallete.error : AppPallete.success),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ex.categoryName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(ex.note, style: GoogleFonts.outfit(color: AppPallete.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                    Text(
                      '${isOut ? "-" : "+"} ${formatRupiah(ex.amount)}',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        color: isOut ? AppPallete.error : AppPallete.success,
                        fontSize: 14,
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

class _NoActiveShiftCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(color: AppPallete.warning.withAlpha(15), borderRadius: BorderRadius.circular(28), border: Border.all(color: AppPallete.warning.withAlpha(30))),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppPallete.warning.withAlpha(30), shape: BoxShape.circle),
            child: const Icon(Icons.lock_clock_rounded, color: AppPallete.warning, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Shift Belum Dimulai', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: AppPallete.textPrimary)),
          const SizedBox(height: 4),
          Text('Statistik real-time akan muncul setelah Anda membuka shift baru.', style: GoogleFonts.outfit(fontSize: 13, color: AppPallete.textSecondary), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _CurrentShiftStats {
  final int totalCashSales;
  final int totalQrisSales;
  final int totalTransactions;
  final List<_SoldProductSummary> soldProducts;
  final int totalCashIn;
  final int totalCashOut;
  final List<ExpenseEntity> expenses;

  const _CurrentShiftStats({
    required this.totalCashSales,
    required this.totalQrisSales,
    required this.totalTransactions,
    required this.soldProducts,
    required this.totalCashIn,
    required this.totalCashOut,
    required this.expenses,
  });
}

class _SoldProductSummary {
  final String name;
  final int quantity;
  const _SoldProductSummary({required this.name, required this.quantity});
}
