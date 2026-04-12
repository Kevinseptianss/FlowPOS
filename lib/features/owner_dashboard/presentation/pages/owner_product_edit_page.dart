import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/currency_input_formatter.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';
import 'package:flow_pos/features/menu_item/presentation/bloc/menu_item_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OwnerProductEditPage extends StatefulWidget {
  final MenuItem menuItem;

  const OwnerProductEditPage({super.key, required this.menuItem});

  static MaterialPageRoute route(MenuItem menuItem) => MaterialPageRoute(
        builder: (context) => OwnerProductEditPage(menuItem: menuItem),
      );

  @override
  State<OwnerProductEditPage> createState() => _OwnerProductEditPageState();
}

class _OwnerProductEditPageState extends State<OwnerProductEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  String? _selectedCategoryId;
  late String _selectedUnit;
  late bool _hasVariants;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _options = [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.menuItem.name);
    _priceController = TextEditingController(text: widget.menuItem.price.toString());
    _selectedCategoryId = widget.menuItem.category.id;
    _selectedUnit = widget.menuItem.unit;
    _hasVariants = widget.menuItem.variants.isNotEmpty;

    // Group variants by option name
    final groupedVariants = <String, List<Map<String, dynamic>>>{};
    for (final v in widget.menuItem.variants) {
      groupedVariants.putIfAbsent(v.optionName, () => []).add({
        'nameController': TextEditingController(text: v.variantName),
        'priceController': TextEditingController(text: v.price.toString()),
        'unit': v.unit,
      });
    }

    for (final entry in groupedVariants.entries) {
      _options.add({
        'nameController': TextEditingController(text: entry.key),
        'variants': entry.value,
      });
    }

    context.read<CategoryBloc>().add(GetAllCategoriesEvent());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    for (var option in _options) {
      option['nameController'].dispose();
      for (var variant in option['variants']) {
        variant['nameController'].dispose();
        variant['priceController'].dispose();
      }
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _options.add({
        'nameController': TextEditingController(),
        'variants': [
          {
            'nameController': TextEditingController(),
            'priceController': TextEditingController(),
            'unit': _selectedUnit,
          }
        ],
      });
    });
  }

  void _removeOption(int index) {
    setState(() {
      _options[index]['nameController'].dispose();
      for (var variant in _options[index]['variants']) {
        variant['nameController'].dispose();
        variant['priceController'].dispose();
      }
      _options.removeAt(index);
    });
  }

  void _addVariant(int optionIndex) {
    setState(() {
      _options[optionIndex]['variants'].add({
        'nameController': TextEditingController(),
        'priceController': TextEditingController(),
        'unit': _selectedUnit,
      });
    });
  }

  void _removeVariant(int optionIndex, int variantIndex) {
    setState(() {
      _options[optionIndex]['variants'][variantIndex]['nameController'].dispose();
      _options[optionIndex]['variants'][variantIndex]['priceController'].dispose();
      _options[optionIndex]['variants'].removeAt(variantIndex);
      
      if (_options[optionIndex]['variants'].isEmpty) {
        _removeOption(optionIndex);
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedCategoryId == null) {
      showSnackbar(context, 'Silakan pilih kategori produk.');
      return;
    }

    if (_hasVariants && _options.isEmpty) {
      showSnackbar(context, 'Silakan tambahkan setidaknya satu opsi varian.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final optionsData = _hasVariants
        ? _options.map((option) {
            return {
              'option_name': option['nameController'].text.trim(),
              'variants': (option['variants'] as List).map((v) {
                final priceText = v['priceController'].text.replaceAll(RegExp(r'[^0-9]'), '');
                return {
                  'name': v['nameController'].text.trim(),
                  'price': int.parse(priceText.isEmpty ? '0' : priceText),
                  'unit': v['unit'],
                };
              }).toList(),
            };
          }).toList()
        : <Map<String, dynamic>>[];

    final mainPriceText = _priceController.text.replaceAll(RegExp(r'[^0-9]'), '');

    context.read<MenuItemBloc>().add(
          UpdateMenuItemEvent(
            id: widget.menuItem.id,
            name: _nameController.text.trim(),
            price: int.parse(mainPriceText.isEmpty ? '0' : mainPriceText),
            categoryId: _selectedCategoryId!,
            unit: _selectedUnit,
            options: optionsData,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      appBar: AppBar(
        title: const Text('Edit Produk'),
        backgroundColor: Colors.white,
        foregroundColor: AppPallete.textPrimary,
        elevation: 0,
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<MenuItemBloc, MenuItemState>(
            listener: (context, state) {
              if (state is MenuItemLoaded && _isSubmitting) {
                setState(() {
                  _isSubmitting = false;
                });
                Navigator.pop(context);
                showSnackbar(context, 'Produk berhasil diperbarui.');
              } else if (state is MenuItemFailure && _isSubmitting) {
                setState(() {
                  _isSubmitting = false;
                });
                showSnackbar(context, state.message);
              }
            },
          ),
          BlocListener<CategoryBloc, CategoryState>(
            listener: (context, state) {
              if (state is CategoryLoaded &&
                  _selectedCategoryId == '__add_new_category_loading__') {
                if (state.categories.isNotEmpty) {
                  setState(() {
                    _selectedCategoryId = state.categories.last.id;
                  });
                } else {
                  setState(() {
                    _selectedCategoryId = null;
                  });
                }
              }
            },
          ),
        ],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Informasi Dasar'),
                const SizedBox(height: 16),
                _buildModernField(
                  child: TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: AppPallete.textPrimary, fontSize: 16),
                    decoration: const InputDecoration(
                      labelText: 'Nama Produk',
                      hintText: 'Masukkan nama produk',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nama produk tidak boleh kosong.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildModernField(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CurrencyInputFormatter()],
                    style: const TextStyle(color: AppPallete.textPrimary, fontSize: 16),
                    decoration: const InputDecoration(
                      labelText: 'Harga Dasar (Rp)',
                      hintText: 'Masukkan harga dasar produk',
                      prefixIcon: Icon(Icons.payments_outlined),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Harga dasar tidak boleh kosong.';
                      }
                      final stripped = value.replaceAll(RegExp(r'[^0-9]'), '');
                      if (int.tryParse(stripped) == null) {
                        return 'Harga harus berupa angka.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildModernField(
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnit,
                    dropdownColor: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    style: const TextStyle(color: AppPallete.textPrimary, fontSize: 16),
                    decoration: const InputDecoration(
                      labelText: 'Jual per',
                      prefixIcon: Icon(Icons.scale_outlined),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'pcs',
                        child: Text('pcs'),
                      ),
                      DropdownMenuItem(
                        value: 'berat',
                        child: Text('berat'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedUnit = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle('Kategori Produk'),
                const SizedBox(height: 16),
                BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, state) {
                    if (state is CategoryLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is CategoryLoaded) {
                      return _buildModernField(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategoryId,
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          style: const TextStyle(color: AppPallete.textPrimary, fontSize: 16),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppPallete.primary),
                          decoration: const InputDecoration(
                            labelText: 'Pilih Kategori',
                            prefixIcon: Icon(Icons.category_outlined),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          items: [
                            ...state.categories.map((category) {
                              return DropdownMenuItem(
                                value: category.id,
                                child: Text(category.name),
                              );
                            }),
                            const DropdownMenuItem(
                              value: '__add_new_category__',
                              child: Row(
                                children: [
                                  Icon(Icons.add_circle_outline,
                                      color: AppPallete.primary),
                                  SizedBox(width: 8),
                                  Text(
                                    'Tambah Kategori Baru',
                                    style: TextStyle(
                                      color: AppPallete.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == '__add_new_category__') {
                              _showAddCategoryModal();
                            } else {
                              setState(() {
                                _selectedCategoryId = value;
                              });
                            }
                          },
                          validator: (value) =>
                              value == null ? 'Kategori wajib dipilih.' : null,
                        ),
                      );
                    }
                    return const Text('Memuat kategori...');
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionTitle('Opsi & Varian'),
                    Switch(
                      value: _hasVariants,
                      activeColor: AppPallete.primary,
                      onChanged: (value) {
                        setState(() => _hasVariants = value);
                        if (value && _options.isEmpty) {
                          _addOption();
                        }
                      },
                    ),
                  ],
                ),
                if (_hasVariants) ...[
                  const SizedBox(height: 16),
                  ..._options.asMap().entries.map((optionEntry) {
                    final optionIndex = optionEntry.key;
                    final option = optionEntry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppPallete.divider),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: option['nameController'],
                                  style: const TextStyle(color: AppPallete.textPrimary, fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    labelText: 'Nama Opsi (Contoh: Ukuran)',
                                    prefixIcon: Icon(Icons.settings_outlined),
                                  ),
                                  validator: (value) => value == null || value.isEmpty ? 'Wajib' : null,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_sweep_outlined, color: AppPallete.error),
                                onPressed: () => _removeOption(optionIndex),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          ... (option['variants'] as List).asMap().entries.map((variantEntry) {
                            final variantIndex = variantEntry.key;
                            final variant = variantEntry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: variant['nameController'],
                                          style: const TextStyle(color: AppPallete.textPrimary, fontSize: 16),
                                          decoration: const InputDecoration(labelText: 'Nama Varian'),
                                          validator: (value) => value == null || value.isEmpty ? 'Wajib' : null,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: AppPallete.error, size: 20),
                                        onPressed: () => _removeVariant(optionIndex, variantIndex),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: variant['priceController'],
                                    style: const TextStyle(color: AppPallete.textPrimary, fontSize: 16),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [CurrencyInputFormatter()],
                                    decoration: const InputDecoration(labelText: 'Harga Tambahan'),
                                    validator: (value) => value == null || value.isEmpty ? 'Wajib' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: variant['unit'],
                                    dropdownColor: Colors.white,
                                    style: const TextStyle(color: AppPallete.textPrimary, fontSize: 16),
                                    decoration: const InputDecoration(
                                      labelText: 'Unit',
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 'pcs', child: Text('pcs')),
                                      DropdownMenuItem(value: 'berat', child: Text('berat')),
                                    ],
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => variant['unit'] = value);
                                      }
                                    },
                                  ),
                                  const Divider(height: 32, thickness: 0.5),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _addVariant(optionIndex),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Tambah Varian ke Opsi Ini'),
                            style: TextButton.styleFrom(foregroundColor: AppPallete.primary),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addOption,
                      icon: const Icon(Icons.library_add_outlined),
                      label: const Text('Tambah Opsi Baru'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppPallete.primary,
                        side: const BorderSide(color: AppPallete.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPallete.primary,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shadowColor: AppPallete.primary.withAlpha(100),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Simpan Perubahan',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppPallete.primary,
      ),
    );
  }

  Widget _buildModernField({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  void _showAddCategoryModal() {
    final categoryNameController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tambah Kategori Baru',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.primary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: categoryNameController,
                autofocus: true,
                style: const TextStyle(color: AppPallete.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'Nama Kategori',
                  hintText: 'Masukkan nama kategori baru',
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final name = categoryNameController.text.trim();
                    if (name.isNotEmpty) {
                      setState(() {
                        _selectedCategoryId = '__add_new_category_loading__';
                      });
                      context.read<CategoryBloc>().add(
                            CreateCategoryEvent(name: name),
                          );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Simpan Kategori'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
