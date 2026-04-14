import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/shift/domain/entities/shift_entity.dart';
import 'package:flow_pos/features/shift/presentation/bloc/shift_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class OwnerShiftHistoryPage extends StatefulWidget {
  const OwnerShiftHistoryPage({super.key});

  static Route route() => MaterialPageRoute(builder: (_) => const OwnerShiftHistoryPage());

  @override
  State<OwnerShiftHistoryPage> createState() => _OwnerShiftHistoryPageState();
}

class _OwnerShiftHistoryPageState extends State<OwnerShiftHistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<ShiftBloc>().add(GetShiftHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Riwayat Shift',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppPallete.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppPallete.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: BlocBuilder<ShiftBloc, ShiftState>(
        builder: (context, state) {
          if (state is ShiftLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ShiftLoaded) {
            return _buildShiftList(context, state.shifts, currencyFormat);
          }
          if (state is ShiftFailure) {
            return Center(child: Text(state.message));
          }
          return const Center(child: Text('Gagal memuat riwayat shift'));
        },
      ),
    );
  }

  Widget _buildShiftList(BuildContext context, List<ShiftEntity> shifts, NumberFormat currency) {
    if (shifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 80, color: AppPallete.primary.withAlpha(40)),
            const SizedBox(height: 16),
            Text('Belum ada data shift', style: GoogleFonts.outfit(color: AppPallete.textSecondary, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: shifts.length,
      itemBuilder: (context, index) {
        final shift = shifts[index];
        return _buildShiftCard(context, shift, currency);
      },
    );
  }

  Widget _buildShiftCard(BuildContext context, ShiftEntity shift, NumberFormat currency) {
    final isClosed = shift.isClosed;
    final totalSales = shift.totalCashSales + shift.totalQrisSales;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showShiftDetail(context, shift, currency),
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, dd MMM yyyy').format(shift.openedAt),
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppPallete.textPrimary),
                      ),
                      Text(
                        'Kasir: ${shift.cashierName ?? "Unknown"}',
                        style: GoogleFonts.outfit(fontSize: 12, color: AppPallete.textSecondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isClosed ? Colors.green.withAlpha(20) : Colors.orange.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isClosed ? 'CLOSED' : 'OPEN',
                      style: GoogleFonts.outfit(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold, 
                        color: isClosed ? Colors.green : Colors.orange
                      ),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(),
              ),
              Row(
                children: [
                  _buildStat(
                    'Waktu Buka',
                    DateFormat('HH:mm').format(shift.openedAt),
                    Icons.access_time_rounded,
                  ),
                  const Spacer(),
                  _buildStat(
                    'Total Penjualan',
                    currency.format(totalSales),
                    Icons.payments_rounded,
                    valueColor: AppPallete.primary,
                  ),
                ],
              ),
              if (isClosed && shift.variance != 0)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(10),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Selisih Saldo: ${currency.format(shift.variance)}',
                        style: GoogleFonts.outfit(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: AppPallete.background, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: AppPallete.textSecondary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.outfit(fontSize: 10, color: AppPallete.textSecondary, fontWeight: FontWeight.bold)),
            Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: valueColor ?? AppPallete.textPrimary, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  void _showShiftDetail(BuildContext context, ShiftEntity shift, NumberFormat currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Detail Laporan Shift', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Saldo Awal', currency.format(shift.openingBalance)),
            _buildDetailRow('Penjualan Tunai', currency.format(shift.totalCashSales)),
            _buildDetailRow('Penjualan QRIS', currency.format(shift.totalQrisSales)),
            _buildDetailRow('Uang Masuk', currency.format(shift.totalCashIn)),
            _buildDetailRow('Uang Keluar', currency.format(shift.totalCashOut)),
            const Divider(height: 32),
            _buildDetailRow('Seharusnya Ada', currency.format(shift.expectedClosingBalance)),
            _buildDetailRow('Saldo Akhir Riil', currency.format(shift.closingBalance ?? 0), isBold: true),
            const SizedBox(height: 8),
            if (shift.isClosed)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: shift.variance == 0 ? Colors.green.withAlpha(15) : Colors.red.withAlpha(15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Selisih (Variance)', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: shift.variance == 0 ? Colors.green : Colors.red)),
                    Text(currency.format(shift.variance), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: shift.variance == 0 ? Colors.green : Colors.red)),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: AppPallete.textSecondary)),
          Text(value, style: GoogleFonts.outfit(fontWeight: isBold ? FontWeight.w900 : FontWeight.bold, fontSize: isBold ? 16 : 14)),
        ],
      ),
    );
  }
}
