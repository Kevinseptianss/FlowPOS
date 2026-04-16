import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_alert.dart';
import 'package:flow_pos/features/store_settings/presentation/bloc/store_settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

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
  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  
  String? _currentSettingsId;
  bool _didInitializeForm = false;

  // Existing payment states (to be preserved during save)
  bool _isCashEnabled = true;
  bool _isCardEnabled = true;
  bool _isTransferEnabled = false;
  bool _isQrisEnabled = false;
  String? _bankName;
  String? _bankNumber;
  String? _midtransMerchantId;
  String? _midtransClientKey;
  String? _midtransServerKey;

  @override
  void initState() {
    super.initState();
    context.read<StoreSettingsBloc>().add(GetStoreSettingsEvent());
  }

  @override
  void dispose() {
    _taxController.dispose();
    _serviceController.dispose();
    _storeNameController.dispose();
    _storeAddressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      appBar: AppBar(
        title: Text('Profil Toko', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: BlocConsumer<StoreSettingsBloc, StoreSettingsState>(
        listener: (context, state) {
          if (state is StoreSettingsFailure) {
            showFlowPOSAlert(
              context: context, 
              title: 'Kesalahan', 
              message: state.message
            );
          }

          if (state is StoreSettingsUpdated) {
            showFlowPOSAlert(
              context: context, 
              title: 'Berhasil', 
              message: 'Profil toko berhasil diperbarui',
              isError: false,
            );
          }

          if (state is StoreSettingsLoaded || state is StoreSettingsUpdated) {
            final settings = state is StoreSettingsLoaded
                ? state.storeSettings
                : (state as StoreSettingsUpdated).storeSettings;

            _currentSettingsId = settings.id.isEmpty ? null : settings.id;

            _isCashEnabled = settings.isCashEnabled;
            _isCardEnabled = settings.isCardEnabled;
            _isTransferEnabled = settings.isTransferEnabled;
            _isQrisEnabled = settings.isQrisEnabled;
            _bankName = settings.bankName;
            _bankNumber = settings.bankAccountNumber;
            _midtransMerchantId = settings.midtransMerchantId;
            _midtransClientKey = settings.midtransClientKey;
            _midtransServerKey = settings.midtransServerKey;

            if (!_didInitializeForm) {
              _storeNameController.text = settings.storeName;
              _storeAddressController.text = settings.storeAddress;
              _taxController.text = _formatInitial(settings.taxPercentage);
              _serviceController.text = _formatInitial(settings.serviceChargePercentage);
              _didInitializeForm = true;
              setState(() {});
            }
          }
        },
        builder: (context, state) {
          final isLoading = state is StoreSettingsLoading;
          final isSaving = state is StoreSettingsUpdating;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Informasi Dasar'),
                  const SizedBox(height: 12),
                  _buildCard(
                    children: [
                      TextFormField(
                        controller: _storeNameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Restoran',
                          prefixIcon: Icon(Icons.store_rounded),
                        ),
                        validator: (v) => v?.trim().isEmpty ?? true ? 'Nama wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _storeAddressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Alamat Toko',
                          prefixIcon: Icon(Icons.map_rounded),
                        ),
                        validator: (v) => v?.trim().isEmpty ?? true ? 'Alamat wajib diisi' : null,
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  _buildSectionHeader('Biaya & Pajak'),
                  const SizedBox(height: 12),
                  _buildCard(
                    children: [
                      TextFormField(
                        controller: _taxController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?$'))],
                        decoration: const InputDecoration(
                          labelText: 'Pajak Restoran',
                          suffixText: '%',
                          prefixIcon: Icon(Icons.receipt_long_rounded),
                        ),
                        validator: _validatePercentage,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _serviceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d{0,2})?$'))],
                        decoration: const InputDecoration(
                          labelText: 'Biaya Layanan (Service)',
                          suffixText: '%',
                          prefixIcon: Icon(Icons.room_service_rounded),
                        ),
                        validator: _validatePercentage,
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading || isSaving ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPallete.primary,
                        foregroundColor: AppPallete.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppPallete.onPrimary),
                            )
                          : Text('Simpan Perubahan', style: GoogleFonts.outfit(
                              color: AppPallete.onPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppPallete.textPrimary,
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPallete.divider.withAlpha(50)),
      ),
      child: Column(children: children),
    );
  }

  String? _validatePercentage(String? value) {
    if (value == null || value.trim().isEmpty) return 'Wajib diisi';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Angka tidak valid';
    if (parsed < 0 || parsed > 100) return '0-100%';
    return null;
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    context.read<StoreSettingsBloc>().add(
      UpdateStoreSettingsEvent(
        id: _currentSettingsId,
        storeName: _storeNameController.text.trim(),
        storeAddress: _storeAddressController.text.trim(),
        taxPercentage: double.parse(_taxController.text.trim()),
        serviceChargePercentage: double.parse(_serviceController.text.trim()),
        isCashEnabled: _isCashEnabled,
        isCardEnabled: _isCardEnabled,
        isTransferEnabled: _isTransferEnabled,
        isQrisEnabled: _isQrisEnabled,
        bankName: _bankName,
        bankAccountNumber: _bankNumber,
        midtransMerchantId: _midtransMerchantId,
        midtransClientKey: _midtransClientKey,
        midtransServerKey: _midtransServerKey,
      ),
    );
  }

  String _formatInitial(double value) {
    if (value == value.truncateToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }
}
