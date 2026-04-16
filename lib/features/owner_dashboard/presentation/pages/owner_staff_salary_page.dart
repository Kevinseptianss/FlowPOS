import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flow_pos/core/services/salary_pdf_service.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/datetime_formatter.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/shift/domain/entities/shift_entity.dart';
import 'package:flow_pos/features/shift/presentation/bloc/shift_bloc.dart';
import 'package:flow_pos/features/staff/data/datasources/salary_remote_data_source.dart';
import 'package:flow_pos/features/staff/data/models/salary_report_model.dart';
import 'package:flow_pos/features/staff/domain/entities/staff_profile.dart';
import 'package:flow_pos/features/staff/presentation/bloc/staff_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

class OwnerStaffSalaryPage extends StatefulWidget {
  const OwnerStaffSalaryPage({super.key});

  static Route route() =>
      MaterialPageRoute(builder: (_) => const OwnerStaffSalaryPage());

  @override
  State<OwnerStaffSalaryPage> createState() => _OwnerStaffSalaryPageState();
}

class _OwnerStaffSalaryPageState extends State<OwnerStaffSalaryPage> {
  final List<SalaryCalculationResult> _calculationResults = [];
  DateTimeRange? _selectedDateRange;
  String? _selectedStaffId; // null or 'all' for everyone
  bool _isCalculating = false;

  late Future<List<SalaryReportModel>> _historyFuture;
  final _salaryDataSource = SalaryRemoteDataSourceImpl(FirebaseFirestore.instance);

  @override
  void initState() {
    super.initState();
    context.read<StaffBloc>().add(GetStaffEvent());
    _historyFuture = _salaryDataSource.getSalaryReports();
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _historyFuture = _salaryDataSource.getSalaryReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: Text(
            'Manajemen Gaji',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w800,
              color: AppPallete.textPrimary,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppPallete.textPrimary,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            indicatorColor: AppPallete.primary,
            labelColor: AppPallete.primary,
            unselectedLabelColor: AppPallete.textSecondary,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Pengaturan'),
              Tab(text: 'Buat Gaji'),
              Tab(text: 'Riwayat'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSettingsTab(),
            _buildGenerateTab(),
            _buildHistoryTab(),
          ],
        ),
      ),
    );
  }

  // --- TAB 1: PENGATURAN GAJI ---

  Widget _buildSettingsTab() {
    return BlocConsumer<StaffBloc, StaffState>(
      listener: (context, state) {
        if (state is StaffSalaryUpdated) {
          showSnackbar(context, 'Pengaturan gaji berhasil disimpan');
        }
      },
      builder: (context, state) {
        if (state is StaffLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is StaffLoaded) {
          final activeStaff = state.staff
              .where((s) => s.isActive && s.role.toLowerCase() != 'owner')
              .toList();
          if (activeStaff.isEmpty) return _buildEmptyState('Belum ada staff aktif');

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: activeStaff.length,
            itemBuilder: (context, index) {
              final staff = activeStaff[index];
              return _buildStaffSettingCard(staff);
            },
          );
        }
        return const Center(child: Text('Gagal memuat data staff'));
      },
    );
  }

  Widget _buildStaffSettingCard(StaffProfile staff) {
    bool isShift = staff.salaryType == 'shift';
    bool isSalarySet = (staff.salary != null && staff.salary! > 0) || 
                       (staff.hourlyRate != null && staff.hourlyRate! > 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        leading: CircleAvatar(
          radius: 26,
          backgroundColor: AppPallete.primary.withAlpha(15),
          child: Text(staff.name[0].toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppPallete.primary)),
        ),
        title: Text(staff.name, style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppPallete.textPrimary)),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: !isSalarySet ? AppPallete.textSecondary.withAlpha(20) : isShift ? Colors.blue.withAlpha(20) : Colors.orange.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                !isSalarySet ? 'BELUM DI ATUR' : isShift ? 'PER SHIFT' : 'BULANAN',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: !isSalarySet ? AppPallete.textSecondary : isShift ? Colors.blue : Colors.orange),
              ),
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: AppPallete.textSecondary),
        onTap: () => _showSalarySettingsDialog(staff),
      ),
    );
  }

  void _showSalarySettingsDialog(StaffProfile staff) {
    String selectedType = staff.salaryType ?? 'fixed';
    final salaryController = TextEditingController(text: staff.salary?.toString() ?? '');
    final hourlyController = TextEditingController(text: staff.hourlyRate?.toString() ?? '');
    final minuteController = TextEditingController(text: staff.minuteRate?.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 32, top: 32, left: 24, right: 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pengaturan Gaji: ${staff.name}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: _buildTypeButton(label: 'Bulanan', isSelected: selectedType == 'fixed', onTap: () => setModalState(() => selectedType = 'fixed'))),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTypeButton(label: 'Per Shift', isSelected: selectedType == 'shift', onTap: () => setModalState(() => selectedType = 'shift'))),
                  ],
                ),
                const SizedBox(height: 24),
                if (selectedType == 'fixed')
                  _buildSalaryField(controller: salaryController, label: 'Gaji Bulanan Tetap', icon: Icons.payments_rounded)
                else
                  Column(
                    children: [
                      _buildSalaryField(controller: hourlyController, label: 'Tarif per Jam', icon: Icons.timer_outlined),
                      const SizedBox(height: 16),
                      _buildSalaryField(controller: minuteController, label: 'Tarif per Menit (Opsional)', icon: Icons.more_time_rounded),
                    ],
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        context.read<StaffBloc>().add(UpdateStaffSalaryEvent(
                          staffId: staff.id,
                          salary: int.tryParse(salaryController.text),
                          salaryType: selectedType,
                          hourlyRate: int.tryParse(hourlyController.text),
                          minuteRate: int.tryParse(minuteController.text),
                        ));
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppPallete.primary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    child: Text('SIMPAN', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- TAB 2: BUAT GAJI ---

  Widget _buildGenerateTab() {
    return MultiBlocListener(
      listeners: [
        BlocListener<ShiftBloc, ShiftState>(
          listener: (context, state) {
            if (state is ShiftLoaded) {
              _calculateSalaries(state.shifts);
            }
          },
        ),
      ],
      child: Column(
        children: [
          _buildRangeOverview(),
          const Divider(height: 1),
          Expanded(
            child: _isCalculating 
              ? const Center(child: CircularProgressIndicator())
              : _calculationResults.isEmpty 
                  ? _buildEmptyState('Pilih rentang tanggal untuk generate gaji')
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _calculationResults.length,
                      itemBuilder: (context, index) {
                        final res = _calculationResults[index];
                        return _buildCalculationResultCard(res);
                      },
                    ),
          ),
          if (_calculationResults.isNotEmpty && !_isCalculating)
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton.icon(
                onPressed: _saveAndGeneratePdf,
                icon: const Icon(Icons.cloud_upload_rounded),
                label: Text('Simpan & Cetak Slip PDF', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(backgroundColor: AppPallete.primary, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRangeOverview() {
    final int totalExpense = _calculationResults.fold(0, (sum, res) => sum + res.totalPay);
    final dateRangeStr = _selectedDateRange == null 
      ? 'Belum pilih tanggal' 
      : '${DatetimeFormatter.formatDateYear(_selectedDateRange!.start)} - ${DatetimeFormatter.formatDateYear(_selectedDateRange!.end)}';

    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: InkWell(
                  onTap: _pickDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(border: Border.all(color: AppPallete.divider), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range_rounded, color: AppPallete.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Periode', style: GoogleFonts.outfit(fontSize: 10, color: AppPallete.textSecondary)),
                              Text(dateRangeStr, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: BlocBuilder<StaffBloc, StaffState>(
                  builder: (context, state) {
                    List<StaffProfile> staffList = [];
                    if (state is StaffLoaded) {
                      staffList = state.staff.where((s) => s.isActive && s.role.toLowerCase() != 'owner').toList();
                    }
                    return DropdownButtonFormField<String>(
                      value: _selectedStaffId ?? 'all',
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        labelText: 'Pilih Staff',
                        labelStyle: GoogleFonts.outfit(fontSize: 10),
                      ),
                      onChanged: (val) => setState(() => _selectedStaffId = val),
                      items: [
                        const DropdownMenuItem(value: 'all', child: Text('Semua Staff', style: TextStyle(fontSize: 12))),
                        ...staffList.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_calculationResults.isEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedDateRange == null ? null : _generateSalary,
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('GENERATE & SCAN SHIFT'),
                style: ElevatedButton.styleFrom(backgroundColor: AppPallete.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
          if (_calculationResults.isNotEmpty) ...[
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Estimasi Gaji:', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                Text(formatRupiah(totalExpense), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppPallete.primary)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalculationResultCard(SalaryCalculationResult res) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppPallete.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppPallete.divider)),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: AppPallete.primary.withAlpha(20), child: Text(res.staffName[0].toUpperCase(), style: const TextStyle(color: AppPallete.primary, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Text(res.staffName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)), Text('${res.shiftCount} Shift • ${res.totalHours}j ${res.totalMinutes}m', style: GoogleFonts.outfit(fontSize: 11, color: AppPallete.textSecondary))],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatRupiah(res.totalPay), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppPallete.success)),
                  InkWell(
                    onTap: () => _showAdjustmentDialog(res),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppPallete.primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_note_rounded, size: 14, color: AppPallete.primary),
                          const SizedBox(width: 4),
                          Text('Sesuaikan', style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppPallete.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (res.bonus > 0 || res.debt > 0 || res.notes != null) ...[
            const Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: Divider(height: 1)),
            Row(
              children: [
                if (res.bonus > 0) _buildAdjustmentBadge('Bonus: +${formatRupiah(res.bonus)}', Colors.green),
                if (res.debt > 0) _buildAdjustmentBadge('Potongan: -${formatRupiah(res.debt)}', Colors.red),
                if (res.notes != null) Expanded(child: Text(' • ${res.notes}', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.outfit(fontSize: 10, color: AppPallete.textSecondary, fontStyle: FontStyle.italic))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- TAB 3: RIWAYAT GAJI ---

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _refreshHistory,
      color: AppPallete.primary,
      child: FutureBuilder<List<SalaryReportModel>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _buildEmptyState('Gagal memuat riwayat: ${snapshot.error}');
          }
          
          final reports = snapshot.data ?? [];
          if (reports.isEmpty) {
            return ListView(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                _buildEmptyState('Belum ada riwayat laporan gaji'),
              ],
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: reports.length,
            physics: const AlwaysScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final report = reports[index];
              return _buildHistoryCard(report);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(SalaryReportModel report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppPallete.divider)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppPallete.primary.withAlpha(10), child: const Icon(Icons.history_edu_rounded, color: AppPallete.primary)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.staffName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
                Text(
                  '${DatetimeFormatter.formatDateYear(report.periodStart)} - ${DatetimeFormatter.formatDateYear(report.periodEnd)}',
                  style: GoogleFonts.outfit(fontSize: 11, color: AppPallete.textSecondary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatRupiah(report.netPay), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppPallete.textPrimary)),
              const SizedBox(height: 4),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.share_rounded, size: 20, color: AppPallete.primary),
                onPressed: () => SalaryPdfService.generateAndShareSlip(report),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- LOGIC & UTILS ---

  void _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppPallete.primary)), child: child!),
    );
    if (range != null) setState(() => _selectedDateRange = range);
  }

  void _generateSalary() {
    if (_selectedDateRange == null) return;
    setState(() => _isCalculating = true);
    context.read<ShiftBloc>().add(GetShiftsByRangeEvent(start: _selectedDateRange!.start, end: _selectedDateRange!.end.add(const Duration(hours: 23, minutes: 59))));
  }

  void _calculateSalaries(List<ShiftEntity> shifts) {
    final staffState = context.read<StaffBloc>().state;
    if (staffState is! StaffLoaded) return;

    final List<SalaryCalculationResult> results = [];
    for (var staff in staffState.staff) {
      if (!staff.isActive || staff.role.toLowerCase() == 'owner') continue;
      if (_selectedStaffId != null && _selectedStaffId != 'all' && staff.id != _selectedStaffId) continue;

      if (staff.salaryType == 'shift') {
        final staffShifts = shifts.where((s) => s.cashierId == staff.id).toList();
        int totalSeconds = 0;
        for (var shift in staffShifts) {
          if (shift.closedAt != null) totalSeconds += shift.closedAt!.difference(shift.openedAt).inSeconds;
        }
        final hours = totalSeconds ~/ 3600;
        final minutes = (totalSeconds % 3600) ~/ 60;
        final pay = (hours * (staff.hourlyRate ?? 0)) + (minutes * (staff.minuteRate ?? 0));
        results.add(SalaryCalculationResult(staffId: staff.id, staffName: staff.name, basePay: pay, totalHours: hours, totalMinutes: minutes, shiftCount: staffShifts.length));
      } else {
        results.add(SalaryCalculationResult(staffId: staff.id, staffName: staff.name, basePay: staff.salary ?? 0, totalHours: 0, totalMinutes: 0, shiftCount: 0));
      }
    }
    setState(() {
      _calculationResults.clear();
      _calculationResults.addAll(results);
      _isCalculating = false;
    });
  }

  void _saveAndGeneratePdf() async {
    if (_selectedDateRange == null) return;
    try {
      showSnackbar(context, 'Menyimpan laporan...');
      final dataSource = SalaryRemoteDataSourceImpl(FirebaseFirestore.instance);
      for (var res in _calculationResults) {
        final report = SalaryReportModel(
          id: const Uuid().v4(),
          staffId: res.staffId,
          staffName: res.staffName,
          periodStart: _selectedDateRange!.start,
          periodEnd: _selectedDateRange!.end,
          basePay: res.basePay,
          bonus: res.bonus,
          debt: res.debt,
          netPay: res.totalPay,
          notes: res.notes,
          createdAt: DateTime.now(),
        );
        await dataSource.saveSalaryReport(report);
      }
      showSnackbar(context, 'Berhasil disimpan!');
      _refreshHistory(); // Refresh history tab data

      if (_calculationResults.isNotEmpty) {
        final last = _calculationResults.last;
        final report = SalaryReportModel(id: 'preview', staffId: last.staffId, staffName: last.staffName, periodStart: _selectedDateRange!.start, periodEnd: _selectedDateRange!.end, basePay: last.basePay, bonus: last.bonus, debt: last.debt, netPay: last.totalPay, notes: last.notes, createdAt: DateTime.now());
        await SalaryPdfService.generateAndShareSlip(report);
      }
      setState(() => _calculationResults.clear());
    } catch (e) {
      showSnackbar(context, 'Gagal: $e');
    }
  }

  void _showAdjustmentDialog(SalaryCalculationResult result) {
    final bonusController = TextEditingController(text: result.bonus.toString());
    final debtController = TextEditingController(text: result.debt.toString());
    final notesController = TextEditingController(text: result.notes ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: AppPallete.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Penyesuaian Gaji',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Text(
                  result.staffName,
                  style: GoogleFonts.outfit(color: AppPallete.textSecondary),
                ),
                const SizedBox(height: 24),
                _buildAdjustField('Bonus (+)', bonusController, Icons.add_circle_outline, Colors.green),
                const SizedBox(height: 16),
                _buildAdjustField('Potongan (-)', debtController, Icons.remove_circle_outline, Colors.red),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  decoration: InputDecoration(
                    labelText: 'Catatan',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      result.bonus = int.tryParse(bonusController.text) ?? 0;
                      result.debt = int.tryParse(debtController.text) ?? 0;
                      result.notes = notesController.text.trim().isEmpty ? null : notesController.text.trim();
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppPallete.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton({required String label, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: isSelected ? AppPallete.primary : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? AppPallete.primary : AppPallete.divider)), child: Center(child: Text(label, style: GoogleFonts.outfit(color: isSelected ? Colors.white : AppPallete.textPrimary, fontWeight: FontWeight.bold)))));
  }

  Widget _buildSalaryField({required TextEditingController controller, required String label, required IconData icon}) {
    return TextFormField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppPallete.primary), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))), validator: (val) => val == null || val.isEmpty ? 'Hubungi admin jika gaji nol' : null);
  }

  Widget _buildAdjustField(String label, TextEditingController controller, IconData icon, Color color) {
    return TextField(controller: controller, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: color), border: OutlineInputBorder(borderRadius: BorderRadius.circular(16))));
  }

  Widget _buildAdjustmentBadge(String label, Color color) {
    return Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(4)), child: Text(label, style: GoogleFonts.outfit(fontSize: 9, fontWeight: FontWeight.bold, color: color)));
  }

  Widget _buildEmptyState(String message) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.info_outline, size: 64, color: AppPallete.textSecondary), const SizedBox(height: 16), Text(message, style: GoogleFonts.outfit(color: AppPallete.textSecondary))]));
  }
}

class SalaryCalculationResult {
  final String staffId;
  final String staffName;
  final int basePay;
  final int totalHours;
  final int totalMinutes;
  final int shiftCount;
  int bonus;
  int debt;
  String? notes;

  SalaryCalculationResult({required this.staffId, required this.staffName, required this.basePay, required this.totalHours, required this.totalMinutes, required this.shiftCount, this.bonus = 0, this.debt = 0, this.notes});

  int get totalPay => basePay + bonus - debt;
}
