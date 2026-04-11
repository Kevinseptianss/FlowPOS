import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/category/domain/entities/category.dart';
import 'package:flow_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flow_pos/features/menu_item/presentation/bloc/menu_item_bloc.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/menu_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddMenuDialog extends StatefulWidget {
  const AddMenuDialog({super.key});

  @override
  State<AddMenuDialog> createState() => _AddMenuDialogState();
}

class _AddMenuDialogState extends State<AddMenuDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _categoryNameController;
  final _formKey = GlobalKey<FormState>();

  String _formType = 'menu';
  String? _selectedCategoryId;
  List<Category> _categoryOptions = const [];
  bool _isSubmitting = false;
  String? _submittingType;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _categoryNameController = TextEditingController();

    context.read<CategoryBloc>().add(GetAllCategoriesEvent());

    final categoryState = context.read<CategoryBloc>().state;
    if (categoryState is CategoryLoaded) {
      _syncCategoryOptions(categoryState.categories);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryNameController.dispose();
    super.dispose();
  }

  void _syncCategoryOptions(List<Category> categories) {
    final filteredCategories = categories
        .where((category) => category.id != 'all')
        .toList(growable: false);

    if (!mounted) {
      return;
    }

    setState(() {
      _categoryOptions = filteredCategories;

      if (_categoryOptions.isNotEmpty) {
        final stillExists = _categoryOptions.any(
          (category) => category.id == _selectedCategoryId,
        );
        if (!stillExists) {
          _selectedCategoryId = _categoryOptions.first.id;
        }
      } else {
        _selectedCategoryId = null;
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_formType == 'menu') {
      if (_selectedCategoryId == null) {
        showSnackbar(context, 'Silakan pilih kategori terlebih dahulu.');
        return;
      }

      final parsedPrice = int.tryParse(_priceController.text.trim());
      if (parsedPrice == null || parsedPrice <= 0) {
        showSnackbar(context, 'Harga harus berupa angka valid lebih besar dari 0.');
        return;
      }

      setState(() {
        _isSubmitting = true;
        _submittingType = 'menu';
      });

      context.read<MenuItemBloc>().add(
        CreateMenuItemEvent(
          name: _nameController.text.trim(),
          price: parsedPrice,
          categoryId: _selectedCategoryId!,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submittingType = 'category';
    });

    context.read<CategoryBloc>().add(
      CreateCategoryEvent(name: _categoryNameController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<MenuItemBloc, MenuItemState>(
          listener: (context, state) {
            if (_submittingType != 'menu') {
              return;
            }

            if (state is MenuItemFailure) {
              setState(() {
                _isSubmitting = false;
                _submittingType = null;
              });
              showSnackbar(context, state.message);
            } else if (state is MenuItemLoaded) {
              setState(() {
                _isSubmitting = false;
                _submittingType = null;
              });
              showSnackbar(context, 'Menu berhasil dibuat.');
              Navigator.pop(context);
            }
          },
        ),
        BlocListener<CategoryBloc, CategoryState>(
          listener: (context, state) {
            if (state is CategoryLoaded) {
              _syncCategoryOptions(state.categories);

              if (_submittingType == 'category') {
                setState(() {
                  _isSubmitting = false;
                  _submittingType = null;
                });
                showSnackbar(context, 'Kategori berhasil dibuat.');
                context.read<MenuItemBloc>().add(GetAllMenuItemsEvent());
                Navigator.pop(context);
              }
            } else if (state is CategoryFailure &&
                _submittingType == 'category') {
              setState(() {
                _isSubmitting = false;
                _submittingType = null;
              });
              showSnackbar(context, state.message);
            }
          },
        ),
      ],
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppPallete.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tambah Menu / Kategori',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: AppPallete.primary),
                  ),
                  // Tombol silang untuk tutup dialog
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: AppPallete.textPrimary,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(), // Garis pemisah tipis
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _SelectionBadge(
                                  label: 'Menu Baru',
                                  isSelected: _formType == 'menu',
                                  onTap: () {
                                    setState(() {
                                      _formType = 'menu';
                                    });
                                  },
                                ),
                                _SelectionBadge(
                                  label: 'Kategori Baru',
                                  isSelected: _formType == 'category',
                                  onTap: () {
                                    setState(() {
                                      _formType = 'category';
                                    });
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_formType == 'menu') ...[
                              MenuField(
                                label: "Nama Menu",
                                hintText: "Ex: Pisang Goreng",
                                controller: _nameController,
                              ),
                              const SizedBox(height: 12),
                              MenuField(
                                label: "Harga",
                                hintText: "Ex: 25000",
                                controller: _priceController,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Kategori',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 12),
                              if (_categoryOptions.isEmpty)
                                Text(
                                  'Kategori tidak ditemukan. Buat kategori terlebih dahulu.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: AppPallete.textSecondary,
                                      ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _categoryOptions
                                      .map(
                                        (category) => _SelectionBadge(
                                          label: category.name,
                                          isSelected:
                                              _selectedCategoryId ==
                                              category.id,
                                          onTap: () {
                                            setState(() {
                                              _selectedCategoryId = category.id;
                                            });
                                          },
                                        ),
                                      )
                                      .toList(),
                                ),
                            ] else ...[
                              MenuField(
                                label: "Nama Kategori",
                                hintText: "Ex: Makanan",
                                controller: _categoryNameController,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppPallete.primary,
                          ),
                          child: const Text('Batal'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppPallete.primary,
                            foregroundColor: AppPallete.onPrimary,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppPallete.onPrimary,
                                  ),
                                )
                              : const Text('Simpan'),
                        ),
                      ],
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
}

class _SelectionBadge extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectionBadge({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppPallete.primary : AppPallete.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppPallete.primary : AppPallete.background,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected ? AppPallete.onPrimary : AppPallete.textPrimary,
          ),
        ),
      ),
    );
  }
}
