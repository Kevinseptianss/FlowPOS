import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/datetime_formatter.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/features/expense/domain/entities/expense_entity.dart';
import 'package:flow_pos/features/expense/presentation/bloc/expense_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class OwnerExpensePage extends StatefulWidget {
  const OwnerExpensePage({super.key});

  @override
  State<OwnerExpensePage> createState() => _OwnerExpensePageState();
}

class _OwnerExpensePageState extends State<OwnerExpensePage> {
  DateTime _startDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
    context.read<ExpenseBloc>().add(GetExpenseCategoriesEvent());
  }

  void _fetchExpenses() {
    final start = DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
    final end = DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);
    context.read<ExpenseBloc>().add(GetExpensesEvent(start: start, end: end));
  }

  void _onDateRangeTap() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppPallete.primary,
              onPrimary: Colors.white,
              onSurface: AppPallete.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _fetchExpenses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      appBar: AppBar(
        title: Text('Pengeluaran & Kas', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            onPressed: _onDateRangeTap,
            icon: const Icon(Icons.calendar_today_rounded),
          ),
        ],
      ),
      body: BlocBuilder<ExpenseBloc, ExpenseState>(
        builder: (context, state) {
          if (state is ExpenseLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExpenseFailure) {
            return Center(child: Text(state.message));
          }
          if (state is ExpensesLoaded) {
            final expenses = state.expenses;
            final totalIn = expenses.where((e) => e.cashActionType == 'CASH_IN').fold(0, (sum, e) => sum + e.amount);
            final totalOut = expenses.where((e) => e.cashActionType == 'CASH_OUT').fold(0, (sum, e) => sum + e.amount);

            return Column(
              children: [
                _buildSummaryHeader(totalIn, totalOut),
                Expanded(
                  child: expenses.isEmpty
                      ? _buildEmptyState()
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: expenses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            return _ExpenseListItem(expense: expenses[index]);
                          },
                        ),
                ),
              ],
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildSummaryHeader(int totalIn, int totalOut) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'TOTAL KAS MASUK',
              value: formatRupiah(totalIn),
              color: AppPallete.success,
              icon: Icons.arrow_downward_rounded,
            ),
          ),
          Container(width: 1, height: 40, color: AppPallete.divider, margin: const EdgeInsets.symmetric(horizontal: 16)),
          Expanded(
            child: _SummaryItem(
              label: 'TOTAL KAS KELUAR',
              value: formatRupiah(totalOut),
              color: AppPallete.error,
              icon: Icons.arrow_upward_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: AppPallete.divider),
          const SizedBox(height: 16),
          Text(
            'Belum ada data pengeluaran',
            style: GoogleFonts.outfit(color: AppPallete.textSecondary, fontWeight: FontWeight.bold),
          ),
          Text(
            'Coba periksa rentang tanggal lain.',
            style: GoogleFonts.outfit(color: AppPallete.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryItem({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(label, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.w900, color: AppPallete.textSecondary, letterSpacing: 0.5)),
          ],
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ),
      ],
    );
  }
}

class _ExpenseListItem extends StatelessWidget {
  final ExpenseEntity expense;
  const _ExpenseListItem({required this.expense});

  @override
  Widget build(BuildContext context) {
    final isOut = expense.cashActionType == 'CASH_OUT';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPallete.divider),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isOut ? AppPallete.error : AppPallete.success).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isOut ? Icons.arrow_outward_rounded : Icons.arrow_back_rounded,
              color: isOut ? AppPallete.error : AppPallete.success,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(expense.categoryName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                    if (expense.isAdjustment) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.withAlpha(50), borderRadius: BorderRadius.circular(4)),
                        child: Text('ADJUST', style: GoogleFonts.outfit(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.orange)),
                      ),
                    ],
                  ],
                ),
                Text(expense.note, style: GoogleFonts.outfit(color: AppPallete.textSecondary, fontSize: 13)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 10, color: AppPallete.textSecondary),
                    const SizedBox(width: 4),
                    Text(expense.staffName, style: GoogleFonts.outfit(fontSize: 10, color: AppPallete.textSecondary)),
                    const SizedBox(width: 12),
                    Icon(Icons.access_time_rounded, size: 10, color: AppPallete.textSecondary),
                    const SizedBox(width: 4),
                    Text(DatetimeFormatter.formatDateYear(expense.createdAt), style: GoogleFonts.outfit(fontSize: 10, color: AppPallete.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${isOut ? "-" : "+"} ${formatRupiah(expense.amount)}',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: isOut ? AppPallete.error : AppPallete.success,
            ),
          ),
        ],
      ),
    );
  }
}
