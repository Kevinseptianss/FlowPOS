import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/store_settings/presentation/bloc/store_settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OwnerStoreProfileSettingsPage extends StatefulWidget {
  static MaterialPageRoute route() => MaterialPageRoute(
    builder: (context) => const OwnerStoreProfileSettingsPage(),
  );

  const OwnerStoreProfileSettingsPage({super.key});

  @override
  State<OwnerStoreProfileSettingsPage> createState() =>
      _OwnerStoreProfileSettingsPageState();
}

class _OwnerStoreProfileSettingsPageState
    extends State<OwnerStoreProfileSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();

  String? _currentSettingsId;
  double _currentTaxPercentage = 0;
  double _currentServiceChargePercentage = 0;
  String _currentStoreName = 'FlowPOS';
  String _currentStoreAddress = 'No Address';

  @override
  void initState() {
    super.initState();
    context.read<StoreSettingsBloc>().add(GetStoreSettingsEvent());
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil Toko',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppPallete.onPrimary),
        ),
      ),
      body: BlocConsumer<StoreSettingsBloc, StoreSettingsState>(
        listener: (context, state) {
          if (state is StoreSettingsFailure) {
            showSnackbar(context, state.message);
          }

          if (state is StoreSettingsUpdated) {
            showSnackbar(context, 'Profil toko berhasil diperbarui');
          }

          if (state is StoreSettingsLoaded || state is StoreSettingsUpdated) {
            final settings = state is StoreSettingsLoaded
                ? state.storeSettings
                : (state as StoreSettingsUpdated).storeSettings;

            _currentSettingsId = settings.id.isEmpty ? null : settings.id;
            _currentTaxPercentage = settings.taxPercentage;
            _currentServiceChargePercentage = settings.serviceChargePercentage;
            _currentStoreName = settings.storeName;
            _currentStoreAddress = settings.storeAddress;
          }
        },
        builder: (context, state) {
          final isLoading = state is StoreSettingsLoading;
          final isSaving = state is StoreSettingsUpdating;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppPallete.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppPallete.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profil Saat Ini',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: AppPallete.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Nama: $_currentStoreName',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppPallete.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Alamat: $_currentStoreAddress',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppPallete.textPrimary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppPallete.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppPallete.divider),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hanya isi kolom yang ingin diubah.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppPallete.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _storeNameController,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppPallete.textPrimary),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(25),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Nama Restoran',
                            hintText: 'Contoh: FlowPOS Cafe',
                            counterText: '',
                          ),
                          validator: _validateStoreName,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _storeAddressController,
                          maxLines: 3,
                          minLines: 2,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppPallete.textPrimary),
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(100),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Alamat Toko',
                            hintText: 'Contoh: Jl. Merdeka No. 10, Jakarta',
                            counterText: '',
                          ),
                          validator: _validateStoreAddress,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading || isSaving ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPallete.primary,
                        foregroundColor: AppPallete.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppPallete.onPrimary,
                              ),
                            )
                          : const Text('Simpan Profil'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String? _validateStoreName(String? value) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return null;
    }

    if (trimmedValue.length > 25) {
      return 'Maksimal 25 karakter';
    }

    return null;
  }

  String? _validateStoreAddress(String? value) {
    final trimmedValue = value?.trim() ?? '';

    if (trimmedValue.isEmpty) {
      return null;
    }

    if (trimmedValue.length > 100) {
      return 'Maksimal 100 karakter';
    }

    return null;
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final updatedStoreName = _storeNameController.text.trim();
    final updatedStoreAddress = _storeAddressController.text.trim();

    if (updatedStoreName.isEmpty && updatedStoreAddress.isEmpty) {
      showSnackbar(context, 'Isi setidaknya satu kolom untuk memperbarui profil');
      return;
    }

    context.read<StoreSettingsBloc>().add(
      UpdateStoreSettingsEvent(
        id: _currentSettingsId,
        taxPercentage: _currentTaxPercentage,
        serviceChargePercentage: _currentServiceChargePercentage,
        storeName: updatedStoreName.isEmpty
            ? _currentStoreName
            : updatedStoreName,
        storeAddress: updatedStoreAddress.isEmpty
            ? _currentStoreAddress
            : updatedStoreAddress,
      ),
    );

    _storeNameController.clear();
    _storeAddressController.clear();
    FocusScope.of(context).unfocus();
  }
}
