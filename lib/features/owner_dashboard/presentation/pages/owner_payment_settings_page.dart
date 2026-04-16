import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_alert.dart';
import 'package:flow_pos/features/store_settings/presentation/bloc/store_settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class OwnerPaymentSettingsPage extends StatefulWidget {
  static MaterialPageRoute route() =>
      MaterialPageRoute(builder: (context) => const OwnerPaymentSettingsPage());

  const OwnerPaymentSettingsPage({super.key});

  @override
  State<OwnerPaymentSettingsPage> createState() =>
      _OwnerPaymentSettingsPageState();
}

class _OwnerPaymentSettingsPageState extends State<OwnerPaymentSettingsPage> {
  final _formKey = GlobalKey<FormState>();

  // Bank Transfer Controllers
  final _bankNameController = TextEditingController();
  final _bankNumberController = TextEditingController();

  // Midtrans Controllers
  final _midtransMerchantIdController = TextEditingController();
  final _midtransClientKeyController = TextEditingController();
  final _midtransServerKeyController = TextEditingController();

  // Midtrans Sandbox Controllers
  final _midtransMerchantIdSandboxController = TextEditingController();
  final _midtransClientKeySandboxController = TextEditingController();
  final _midtransServerKeySandboxController = TextEditingController();

  String? _currentSettingsId;
  String? _currentStoreName;
  String? _currentStoreAddress;
  double? _currentTax;
  double? _currentService;
  bool _didInitializeForm = false;

  // Payment State
  bool _isCashEnabled = true;
  bool _isCardEnabled = true;
  bool _isTransferEnabled = false;
  bool _isQrisEnabled = false;
  bool _isMidtransSandbox = true;

  @override
  void initState() {
    super.initState();
    context.read<StoreSettingsBloc>().add(GetStoreSettingsEvent());
  }

  Future<void> _launchMidtransDashboard() async {
    final Uri url = Uri.parse(
      'https://dashboard.midtrans.com/settings/access-keys',
    );
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted)
        showFlowPOSAlert(
          context: context, 
          title: 'Kesalahan', 
          message: 'Tidak dapat membuka dashboard Midtrans'
        );
    }
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _bankNumberController.dispose();
    _midtransMerchantIdController.dispose();
    _midtransClientKeyController.dispose();
    _midtransServerKeyController.dispose();
    _midtransMerchantIdSandboxController.dispose();
    _midtransClientKeySandboxController.dispose();
    _midtransServerKeySandboxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      appBar: AppBar(
        title: Text(
          'Metode Pembayaran',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
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
              message: 'Metode pembayaran berhasil diperbarui',
              isError: false,
            );
          }

          if (state is StoreSettingsLoaded || state is StoreSettingsUpdated) {
            final settings = state is StoreSettingsLoaded
                ? state.storeSettings
                : (state as StoreSettingsUpdated).storeSettings;

            _currentSettingsId = settings.id.isEmpty ? null : settings.id;
            _currentStoreName = settings.storeName;
            _currentStoreAddress = settings.storeAddress;
            _currentTax = settings.taxPercentage;
            _currentService = settings.serviceChargePercentage;

            if (!_didInitializeForm) {
              _isCashEnabled = settings.isCashEnabled;
              _isCardEnabled = settings.isCardEnabled;
              _isTransferEnabled = settings.isTransferEnabled;
              _isQrisEnabled = settings.isQrisEnabled;

              _bankNameController.text = settings.bankName ?? '';
              _bankNumberController.text = settings.bankAccountNumber ?? '';
              _midtransMerchantIdController.text =
                  settings.midtransMerchantId ?? '';
              _midtransClientKeyController.text =
                  settings.midtransClientKey ?? '';
              _midtransServerKeyController.text =
                  settings.midtransServerKey ?? '';

              _isMidtransSandbox = settings.isMidtransSandbox;
              _midtransMerchantIdSandboxController.text =
                  settings.midtransMerchantIdSandbox ?? '';
              _midtransClientKeySandboxController.text =
                  settings.midtransClientKeySandbox ?? '';
              _midtransServerKeySandboxController.text =
                  settings.midtransServerKeySandbox ?? '';

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
                  Text(
                    'Pilih metode pembayaran yang tersedia di kasir Anda.',
                    style: GoogleFonts.outfit(
                      color: AppPallete.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildPaymentMethodCard(
                    title: 'Tunai (Cash)',
                    subtitle: 'Terima pembayaran uang tunai fisik.',
                    icon: Icons.payments_rounded,
                    value: _isCashEnabled,
                    onChanged: (v) => setState(() => _isCashEnabled = v),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentMethodCard(
                    title: 'Kartu (Card)',
                    subtitle: 'Pembayaran Debit/Kredit via EDC.',
                    icon: Icons.credit_card_rounded,
                    value: _isCardEnabled,
                    onChanged: (v) => setState(() => _isCardEnabled = v),
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentMethodCard(
                    title: 'Transfer Bank',
                    subtitle: 'Tampilkan info rekening ke pelanggan.',
                    icon: Icons.account_balance_rounded,
                    value: _isTransferEnabled,
                    onChanged: (v) => setState(() => _isTransferEnabled = v),
                    extraFields: _isTransferEnabled
                        ? [
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _bankNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nama Bank',
                                hintText: 'Misal: BCA / Mandiri',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _bankNumberController,
                              decoration: const InputDecoration(
                                labelText: 'Nomor Rekening',
                                hintText: '1234567890',
                              ),
                            ),
                          ]
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _buildPaymentMethodCard(
                    title: 'QRIS (Midtrans)',
                    subtitle: 'Generate QRIS otomatis & aman.',
                    icon: Icons.qr_code_scanner_rounded,
                    color: Colors.blue,
                    value: _isQrisEnabled,
                    onChanged: (v) => setState(() => _isQrisEnabled = v),
                    extraFields: _isQrisEnabled
                        ? [
                            const SizedBox(height: 20),
                            SwitchListTile(
                              title: Text(
                                'Sandbox Mode (Testing)',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: const Text(
                                'Gunakan untuk testing tanpa pembayaran asli.',
                              ),
                              value: _isMidtransSandbox,
                              onChanged: (v) =>
                                  setState(() => _isMidtransSandbox = v),
                              activeColor: Colors.orange,
                              contentPadding: EdgeInsets.zero,
                            ),
                            const Divider(),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(10),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.blue.withAlpha(30),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.info_outline_rounded,
                                        color: Colors.blue,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Cara Mendapatkan Key:',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildTutorialStep(
                                    '1',
                                    'Login ke Dashboard Midtrans.',
                                  ),
                                  _buildTutorialStep(
                                    '2',
                                    'Gunakan toggle di pojok kiri atas untuk beralih antara Sandbox dan Production.',
                                  ),
                                  _buildTutorialStep(
                                    '3',
                                    'Buka menu Settings > Access Keys untuk menyalin API Keys.',
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _launchMidtransDashboard,
                                      icon: const Icon(
                                        Icons.open_in_new_rounded,
                                        size: 18,
                                      ),
                                      label: const Text(
                                        'Buka Dashboard Midtrans',
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.blue,
                                        side: const BorderSide(
                                          color: Colors.blue,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            if (!_isMidtransSandbox) ...[
                              Text(
                                'Produksi (LIVE)',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _midtransMerchantIdController,
                                decoration: const InputDecoration(
                                  labelText: 'Production Merchant ID',
                                ),
                                onChanged: (v) {
                                  if (v.startsWith('SB-')) setState(() {});
                                },
                              ),
                              if (_midtransMerchantIdController.text.startsWith(
                                'SB-',
                              ))
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '⚠️ Peringatan: Anda memasukkan key Sandbox di kolom Produksi!',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _midtransClientKeyController,
                                decoration: const InputDecoration(
                                  labelText: 'Production Client Key',
                                ),
                                onChanged: (v) {
                                  if (v.startsWith('SB-')) setState(() {});
                                },
                              ),
                              if (_midtransClientKeyController.text.startsWith(
                                'SB-',
                              ))
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '⚠️ Peringatan: Anda memasukkan key Sandbox di kolom Produksi!',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _midtransServerKeyController,
                                decoration: const InputDecoration(
                                  labelText: 'Production Server Key',
                                  helperText:
                                      'Dapatkan dari Dashboard Midtrans mode Production.',
                                ),
                                onChanged: (v) {
                                  if (v.startsWith('SB-')) setState(() {});
                                },
                              ),
                              if (_midtransServerKeyController.text.startsWith(
                                'SB-',
                              ))
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '⚠️ Peringatan: Anda memasukkan key Sandbox di kolom Produksi!',
                                    style: TextStyle(
                                      color: Colors.red[700],
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ] else ...[
                              Text(
                                'Sandbox (TEST)',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller:
                                    _midtransMerchantIdSandboxController,
                                decoration: const InputDecoration(
                                  labelText: 'Sandbox Merchant ID',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _midtransClientKeySandboxController,
                                decoration: const InputDecoration(
                                  labelText: 'Sandbox Client Key',
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _midtransServerKeySandboxController,
                                decoration: const InputDecoration(
                                  labelText: 'Sandbox Server Key',
                                  helperText:
                                      'Gunakan key yang berawalan SB- dari Dashboard Midtrans.',
                                ),
                              ),
                            ],
                          ]
                        : null,
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppPallete.onPrimary,
                              ),
                            )
                          : Text(
                              'Simpan Pengaturan',
                              style: GoogleFonts.outfit(
                                color: AppPallete.onPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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

  Widget _buildTutorialStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number.',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.blue.withAlpha(200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? color,
    List<Widget>? extraFields,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: value
              ? (color ?? AppPallete.primary).withAlpha(100)
              : AppPallete.divider.withAlpha(50),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (color ?? AppPallete.primary).withAlpha(
                    value ? 25 : 10,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: value
                      ? (color ?? AppPallete.primary)
                      : AppPallete.textSecondary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppPallete.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeColor: color ?? AppPallete.primary,
              ),
            ],
          ),
          if (extraFields != null) ...extraFields,
        ],
      ),
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    context.read<StoreSettingsBloc>().add(
      UpdateStoreSettingsEvent(
        id: _currentSettingsId,
        taxPercentage: _currentTax ?? 0,
        serviceChargePercentage: _currentService ?? 0,
        storeName: _currentStoreName ?? 'FlowPOS',
        storeAddress: _currentStoreAddress ?? '',
        isCashEnabled: _isCashEnabled,
        isCardEnabled: _isCardEnabled,
        isTransferEnabled: _isTransferEnabled,
        bankName: _bankNameController.text.trim(),
        bankAccountNumber: _bankNumberController.text.trim(),
        isQrisEnabled: _isQrisEnabled,
        midtransMerchantId: _midtransMerchantIdController.text.trim(),
        midtransClientKey: _midtransClientKeyController.text.trim(),
        midtransServerKey: _midtransServerKeyController.text.trim(),
        isMidtransSandbox: _isMidtransSandbox,
        midtransMerchantIdSandbox: _midtransMerchantIdSandboxController.text
            .trim(),
        midtransClientKeySandbox: _midtransClientKeySandboxController.text
            .trim(),
        midtransServerKeySandbox: _midtransServerKeySandboxController.text
            .trim(),
      ),
    );
  }
}
