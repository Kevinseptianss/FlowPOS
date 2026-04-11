import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/modifier_option/domain/entities/create_modifier_option_input.dart';
import 'package:flow_pos/features/modifier_option/presentation/bloc/modifier_option_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OwnerModifierGroupCreatePage extends StatefulWidget {
  const OwnerModifierGroupCreatePage({super.key});

  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (context) => const OwnerModifierGroupCreatePage(),
  );

  @override
  State<OwnerModifierGroupCreatePage> createState() =>
      _OwnerModifierGroupCreatePageState();
}

class _OwnerModifierGroupCreatePageState
    extends State<OwnerModifierGroupCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final List<_ModifierOptionDraft> _optionDrafts = [];

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _addOptionRow();
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    for (final draft in _optionDrafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void _addOptionRow() {
    setState(() {
      _optionDrafts.add(_ModifierOptionDraft());
    });
  }

  void _removeOptionRow(int index) {
    if (_optionDrafts.length <= 1) {
      return;
    }

    setState(() {
      final draft = _optionDrafts.removeAt(index);
      draft.dispose();
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final options = <CreateModifierOptionInput>[];

    for (final draft in _optionDrafts) {
      final name = draft.nameController.text.trim();
      final additionalPriceRaw = draft.additionalPriceController.text.trim();
      final additionalPrice = int.tryParse(additionalPriceRaw);

      if (name.isEmpty || additionalPrice == null || additionalPrice < 0) {
        showSnackbar(
          context,
          'Silakan masukkan nama dan harga yang valid untuk setiap pilihan.',
        );
        return;
      }

      options.add(
        CreateModifierOptionInput(name: name, additionalPrice: additionalPrice),
      );
    }

    if (options.isEmpty) {
      showSnackbar(context, 'Tambahkan setidaknya satu pilihan tambahan.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    context.read<ModifierOptionBloc>().add(
      CreateModifierGroupEvent(
        groupName: _groupNameController.text.trim(),
        options: options,
      ),
    );
  }

  void _resetForm() {
    _groupNameController.clear();

    for (final draft in _optionDrafts) {
      draft.dispose();
    }

    _optionDrafts
      ..clear()
      ..add(_ModifierOptionDraft());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Grup Tambahan Baru',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppPallete.onPrimary),
        ),
      ),
      body: BlocListener<ModifierOptionBloc, ModifierOptionState>(
        listener: (context, state) {
          if (state is ModifierOptionFailure && _isSubmitting) {
            setState(() {
              _isSubmitting = false;
            });
            showSnackbar(context, state.message);
          }

          if (state is ModifierGroupCreatedSuccess && _isSubmitting) {
            setState(() {
              _isSubmitting = false;
            });
            _resetForm();
            showSnackbar(context, 'Grup tambahan berhasil dibuat.');
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Grup',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppPallete.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _groupNameController,
                      textInputAction: TextInputAction.next,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppPallete.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Nama Grup Tambahan',
                        hintText: 'Contoh: Topping, Level Gula, Ukuran',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Nama grup tambahan wajib diisi.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pilihan Tambahan',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: AppPallete.primary,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        TextButton.icon(
                          onPressed: _isSubmitting ? null : _addOptionRow,
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Pilihan'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._optionDrafts.asMap().entries.map((entry) {
                      final index = entry.key;
                      final draft = entry.value;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: draft.nameController,
                                textInputAction: TextInputAction.next,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppPallete.textPrimary),
                                decoration: InputDecoration(
                                  labelText: 'Nama Pilihan ${index + 1}',
                                  hintText: 'Contoh: Ekstra Keju',
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: draft.additionalPriceController,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppPallete.textPrimary),
                                decoration: const InputDecoration(
                                  labelText: 'Harga',
                                  hintText: 'Contoh: 5000',
                                ),
                                validator: (value) {
                                  final price = int.tryParse(
                                    value?.trim() ?? '',
                                  );
                                  if (price == null || price < 0) {
                                    return 'Tidak valid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              color: AppPallete.error,
                              onPressed: _isSubmitting
                                  ? null
                                  : () => _removeOptionRow(index),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppPallete.primary,
                  foregroundColor: AppPallete.onPrimary,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppPallete.onPrimary,
                        ),
                      )
                    : const Text('Simpan Grup Tambahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModifierOptionDraft {
  final TextEditingController nameController;
  final TextEditingController additionalPriceController;

  _ModifierOptionDraft()
    : nameController = TextEditingController(),
      additionalPriceController = TextEditingController(text: '0');

  void dispose() {
    nameController.dispose();
    additionalPriceController.dispose();
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPallete.divider),
      ),
      child: child,
    );
  }
}
