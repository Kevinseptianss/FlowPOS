import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/menu_field.dart';
import 'package:flutter/material.dart';

class AddMenuDialog extends StatefulWidget {
  const AddMenuDialog({super.key});

  @override
  State<AddMenuDialog> createState() => _AddMenuDialogState();
}

class _AddMenuDialogState extends State<AddMenuDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _categoryController;
  late final TextEditingController _categoryNameController;
  final _formKey = GlobalKey<FormState>();
  String _formType = 'menu';
  String _selectedCategory = 'Beverage';

  static const List<String> _categoryOptions = [
    'Beverage',
    'Food',
    'Pastry',
    'Snack',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _priceController = TextEditingController();
    _categoryController = TextEditingController();
    _categoryNameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                  icon: const Icon(Icons.close, color: AppPallete.textPrimary),
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
                              hintText: "Ex: John Doe",
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _categoryOptions
                                  .map(
                                    (category) => _SelectionBadge(
                                      label: category,
                                      isSelected: _selectedCategory == category,
                                      onTap: () {
                                        setState(() {
                                          _selectedCategory = category;
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
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            if (_formType == 'menu') {
                              print('submit_menu');
                            } else {
                              print('submit_category');
                            }
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPallete.primary,
                          foregroundColor: AppPallete.onPrimary,
                        ),
                        child: const Text('Simpan'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
