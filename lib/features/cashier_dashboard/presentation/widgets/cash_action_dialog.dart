import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/currency_input_formatter.dart';
import 'package:flow_pos/features/expense/domain/entities/expense_category.dart';
import 'package:flow_pos/features/expense/domain/entities/expense_entity.dart';
import 'package:flow_pos/features/expense/presentation/bloc/expense_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

class CashActionDialog extends StatefulWidget {
  final String staffId;
  final String staffName;
  final String shiftId;

  const CashActionDialog({
    super.key,
    required this.staffId,
    required this.staffName,
    required this.shiftId,
  });

  @override
  State<CashActionDialog> createState() => _CashActionDialogState();
}

class _CashActionDialogState extends State<CashActionDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedType = 'CASH_OUT'; // 'CASH_IN' or 'CASH_OUT'
  ExpenseCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(GetExpenseCategoriesEvent());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 460,
        decoration: BoxDecoration(
          color: AppPallete.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTypeSelector(),
                      const SizedBox(height: 24),
                      _buildCategoryPicker(),
                      const SizedBox(height: 24),
                      _buildAmountField(),
                      const SizedBox(height: 24),
                      _buildNoteField(),
                      const SizedBox(height: 32),
                      _buildActionButtons(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isOut = _selectedType == 'CASH_OUT';
    return Container(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOut 
              ? [AppPallete.error, AppPallete.error.withAlpha(200)]
              : [AppPallete.success, AppPallete.success.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isOut ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOut ? 'Kas Keluar' : 'Kas Masuk',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                Text(
                  isOut ? 'Catat pengeluaran tunai dari laci.' : 'Catat penambahan tunai ke laci.',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _TypeButton(
            label: 'Out (Keluar)',
            isSelected: _selectedType == 'CASH_OUT',
            color: AppPallete.error,
            onTap: () => setState(() {
              _selectedType = 'CASH_OUT';
              _selectedCategory = null;
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _TypeButton(
            label: 'In (Masuk)',
            isSelected: _selectedType == 'CASH_IN',
            color: AppPallete.success,
            onTap: () => setState(() {
              _selectedType = 'CASH_IN';
              _selectedCategory = null;
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPicker() {
    return BlocBuilder<ExpenseBloc, ExpenseState>(
      builder: (context, state) {
        List<ExpenseCategory> filteredCategories = [];
        if (state is ExpenseCategoriesLoaded) {
          final targetType = _selectedType == 'CASH_OUT' ? 'OUT' : 'IN';
          filteredCategories = state.categories.where((c) => c.type == targetType).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kategori',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppPallete.textSecondary),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ExpenseCategory>(
              value: _selectedCategory,
              hint: Text('Pilih Kategori', style: GoogleFonts.outfit(fontSize: 14)),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppPallete.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              items: filteredCategories.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c.name, style: GoogleFonts.outfit(fontSize: 14)),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedCategory = val),
              validator: (val) => val == null ? 'Pilih kategori' : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAmountField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Jumlah Nominal',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppPallete.textSecondary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppPallete.textPrimary),
          decoration: InputDecoration(
            prefixText: 'Rp ',
            prefixStyle: GoogleFonts.outfit(color: AppPallete.textSecondary),
            filled: true,
            fillColor: AppPallete.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.all(20),
          ),
          validator: (val) {
            if (val == null || val.isEmpty || val == '0') return 'Masukkan nominal';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Catatan / Alasan',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppPallete.textSecondary),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _noteController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Contoh: Beli Es Batu, Koreksi Kas, dll',
            filled: true,
            fillColor: AppPallete.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          validator: (val) => val == null || val.isEmpty ? 'Masukkan catatan' : null,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return BlocConsumer<ExpenseBloc, ExpenseState>(
      listener: (context, state) {
        if (state is ExpenseCreated) {
          Navigator.pop(context, true);
        } else if (state is ExpenseFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      builder: (context, state) {
        return Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Batal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppPallete.textSecondary)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: state is ExpenseLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedType == 'CASH_OUT' ? AppPallete.error : AppPallete.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: state is ExpenseLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('SIMPAN', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
              ),
            ),
          ],
        );
      },
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final amount = int.parse(_amountController.text.replaceAll(RegExp(r'[^0-9]'), ''));
      final expense = ExpenseEntity(
        id: const Uuid().v4(),
        amount: amount,
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        note: _noteController.text.trim(),
        type: 'SHIFT',
        cashActionType: _selectedType,
        staffId: widget.staffId,
        staffName: widget.staffName,
        shiftId: widget.shiftId,
        createdAt: DateTime.now(),
      );
      context.read<ExpenseBloc>().add(CreateExpenseEvent(expense));
    }
  }
}

class _TypeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : AppPallete.divider),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.outfit(
              color: isSelected ? Colors.white : AppPallete.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
