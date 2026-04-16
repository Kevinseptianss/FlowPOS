import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/expense/domain/entities/expense_category.dart';
import 'package:flow_pos/features/expense/presentation/bloc/expense_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

class OwnerExpenseCategoryPage extends StatefulWidget {
  const OwnerExpenseCategoryPage({super.key});

  @override
  State<OwnerExpenseCategoryPage> createState() => _OwnerExpenseCategoryPageState();
}

class _OwnerExpenseCategoryPageState extends State<OwnerExpenseCategoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<ExpenseBloc>().add(GetExpenseCategoriesEvent());
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    String type = 'OUT';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 32,
            left: 32,
            right: 32,
            top: 32,
          ),
          decoration: const BoxDecoration(
            color: AppPallete.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tambah Kategori', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              Text('Tipe Kategori', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppPallete.textSecondary)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _TypeOption(
                    label: 'Pengeluaran (Out)',
                    isSelected: type == 'OUT',
                    onTap: () => setModalState(() => type = 'OUT'),
                  ),
                  const SizedBox(width: 12),
                  _TypeOption(
                    label: 'Pemasukan (In)',
                    isSelected: type == 'IN',
                    onTap: () => setModalState(() => type = 'IN'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Nama Kategori', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: AppPallete.textSecondary)),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Contoh: Operasional, Beli Bahan, dll',
                  filled: true,
                  fillColor: AppPallete.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  final category = ExpenseCategory(
                    id: const Uuid().v4(),
                    name: nameController.text.trim(),
                    type: type,
                  );
                  context.read<ExpenseBloc>().add(CreateExpenseCategoryEvent(category));
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPallete.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('SIMPAN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      appBar: AppBar(
        title: Text('Pengaturan Kategori Kas', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        backgroundColor: AppPallete.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Kategori', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: BlocConsumer<ExpenseBloc, ExpenseState>(
        listener: (context, state) {
          if (state is ExpenseCategoryCreated || state is ExpenseCategoryDeleted) {
            context.read<ExpenseBloc>().add(GetExpenseCategoriesEvent());
            showSnackbar(context, 'Berhasil memperbarui kategori');
          }
        },
        builder: (context, state) {
          if (state is ExpenseLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ExpenseCategoriesLoaded) {
            final categories = state.categories;
            if (categories.isEmpty) {
              return Center(child: Text('Belum ada kategori.', style: GoogleFonts.outfit(color: AppPallete.textSecondary)));
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                return _CategoryTile(category: cat);
              },
            );
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeOption({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppPallete.primary : AppPallete.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? AppPallete.primary : AppPallete.divider),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: isSelected ? Colors.white : AppPallete.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final ExpenseCategory category;
  const _CategoryTile({required this.category});

  @override
  Widget build(BuildContext context) {
    final isOut = category.type == 'OUT';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppPallete.divider),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isOut ? AppPallete.error : AppPallete.success).withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isOut ? Icons.remove_circle_outline_rounded : Icons.add_circle_outline_rounded,
            color: isOut ? AppPallete.error : AppPallete.success,
            size: 20,
          ),
        ),
        title: Text(category.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        subtitle: Text(isOut ? 'Tipe: Pengeluaran' : 'Tipe: Pemasukan', style: GoogleFonts.outfit(fontSize: 12)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppPallete.error, size: 20),
          onPressed: () {
            context.read<ExpenseBloc>().add(DeleteExpenseCategoryEvent(category.id));
          },
        ),
      ),
    );
  }
}
