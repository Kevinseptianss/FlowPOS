import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/store_settings/presentation/bloc/store_settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OwnerStoreSettingsPage extends StatefulWidget {
  static MaterialPageRoute route() =>
      MaterialPageRoute(builder: (context) => const OwnerStoreSettingsPage());

  const OwnerStoreSettingsPage({super.key});

  @override
  State<OwnerStoreSettingsPage> createState() => _OwnerStoreSettingsPageState();
}

class _OwnerStoreSettingsPageState extends State<OwnerStoreSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _taxController = TextEditingController();
  final _serviceController = TextEditingController();

  String? _currentSettingsId;
  bool _didInitializeForm = false;

  @override
  void initState() {
    super.initState();
    context.read<StoreSettingsBloc>().add(StartStoreSettingsRealtimeEvent());
  }

  @override
  void dispose() {
    _taxController.dispose();
    _serviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tax & Service Charge',
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
            showSnackbar(context, 'Store settings updated successfully');
          }

          if (state is StoreSettingsLoaded || state is StoreSettingsUpdated) {
            final settings = state is StoreSettingsLoaded
                ? state.storeSettings
                : (state as StoreSettingsUpdated).storeSettings;

            _currentSettingsId = settings.id.isEmpty ? null : settings.id;

            if (!_didInitializeForm) {
              _taxController.text = _formatInitial(settings.taxPercentage);
              _serviceController.text = _formatInitial(
                settings.serviceChargePercentage,
              );
              _didInitializeForm = true;
            }
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
                          'Set percentage values used on cashier checkout.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppPallete.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _taxController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d{0,3}(\.\d{0,2})?$'),
                            ),
                          ],
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppPallete.textPrimary),
                          decoration: const InputDecoration(
                            labelText: 'Tax Percentage',
                            hintText: 'Example: 11.00',
                            suffixText: '%',
                          ),
                          validator: _validatePercentage,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _serviceController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: AppPallete.textPrimary),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d{0,3}(\.\d{0,2})?$'),
                            ),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Service Charge Percentage',
                            hintText: 'Example: 5.00',
                            suffixText: '%',
                          ),
                          validator: _validatePercentage,
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
                          : const Text('Save Settings'),
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

  String? _validatePercentage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Value is required';
    }

    final parsed = double.tryParse(value.trim());
    if (parsed == null) {
      return 'Invalid number';
    }

    if (parsed < 0 || parsed > 100) {
      return 'Value must be between 0 and 100';
    }

    return null;
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final tax = double.parse(_taxController.text.trim());
    final service = double.parse(_serviceController.text.trim());

    context.read<StoreSettingsBloc>().add(
      UpdateStoreSettingsEvent(
        id: _currentSettingsId,
        taxPercentage: tax,
        serviceChargePercentage: service,
      ),
    );
  }

  String _formatInitial(double value) {
    if (value == value.truncateToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(2);
  }
}
