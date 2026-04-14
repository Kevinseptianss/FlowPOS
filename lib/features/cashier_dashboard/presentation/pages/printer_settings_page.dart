import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/services/thermal_receipt_printer_service.dart';
import 'package:flow_pos/core/services/printer_local_service.dart';
import 'package:flow_pos/features/store_settings/presentation/bloc/store_settings_bloc.dart';
import 'package:flow_pos/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class PrinterSettingsPage extends StatefulWidget {
  const PrinterSettingsPage({super.key});

  @override
  State<PrinterSettingsPage> createState() => _PrinterSettingsPageState();
}

class _PrinterSettingsPageState extends State<PrinterSettingsPage> {
  late final ThermalReceiptPrinterService _printerService;
  late final PrinterLocalService _printerLocalService;
  
  PrinterSettings? _currentSettings;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _printerService = serviceLocator<ThermalReceiptPrinterService>();
    _printerLocalService = serviceLocator<PrinterLocalService>();
    _loadSettings();
  }

  void _loadSettings() {
    setState(() {
      _currentSettings = _printerLocalService.getSettings();
    });
  }

  Future<void> _selectPrinter() async {
    final device = await _printerService.selectDevice(context: context);
    if (device != null) {
      await _printerLocalService.saveSettings(
        deviceName: device.name,
        deviceAddress: device.macAddress,
        charsPerLine: _currentSettings?.charsPerLine ?? 32,
      );
      _loadSettings();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Printer ${device.name} terpilih')),
        );
      }
    }
  }

  Future<void> _updateCharsPerLine(int value) async {
    await _printerLocalService.saveSettings(
      deviceName: _currentSettings?.deviceName,
      deviceAddress: _currentSettings?.deviceAddress,
      charsPerLine: value,
    );
    _loadSettings();
  }

  Future<void> _testPrint() async {
    if (_currentSettings?.deviceAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih printer terlebih dahulu!'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isConnecting = true);
    try {
      final storeSettingsState = context.read<StoreSettingsBloc>().state;
      if (storeSettingsState is! StoreSettingsLoaded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal memuat pengaturan toko')),
        );
        return;
      }

      final userState = context.read<UserBloc>().state;
      final cashierName = userState is UserLoggedIn ? userState.user.name : 'Kasir';

      await _printerService.connect(macAddress: _currentSettings!.deviceAddress!);
      await _printerService.printTestReceipt(
        context: context,
        storeSettings: storeSettingsState.storeSettings,
        cashierName: cashierName,
      );
      await _printerService.disconnect();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Test print berhasil dikirim'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal cetak: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      appBar: AppBar(
        title: Text(
          'Pengaturan Printer',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             _buildPrinterCard(),
            const SizedBox(height: 32),
            Text(
              'Pratinjau Struk',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: AppPallete.textPrimary),
            ),
            const SizedBox(height: 16),
            _buildReceiptPreview(),
            const SizedBox(height: 32),
            _buildTipsCard(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPrinterCard() {
    final hasDevice = _currentSettings?.deviceAddress != null;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
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
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPallete.primary.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.print_rounded, color: AppPallete.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasDevice ? _currentSettings!.deviceName! : 'Printer Belum Terhubung',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 18, color: AppPallete.textPrimary),
                    ),
                    Text(
                      hasDevice ? _currentSettings!.deviceAddress! : 'Klik tombol di samping untuk mencari',
                      style: GoogleFonts.outfit(fontSize: 12, color: AppPallete.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton.filled(
                onPressed: _selectPrinter,
                icon: const Icon(Icons.bluetooth_searching_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppPallete.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Text(
            'Lebar Kertas',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppPallete.textPrimary, fontSize: 16),
          ),
          Text(
            'Geser untuk menyesuaikan karakter per baris',
            style: GoogleFonts.outfit(fontSize: 12, color: AppPallete.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildPresetButton(32, '58mm\n(32 char)'),
              const SizedBox(width: 12),
              _buildPresetButton(42, '80mm\n(42 char)'),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: (_currentSettings?.charsPerLine ?? 32).toDouble(),
                  min: 20,
                  max: 64,
                  divisions: 44,
                  activeColor: AppPallete.primary,
                  onChanged: (val) => _updateCharsPerLine(val.toInt()),
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppPallete.primary.withAlpha(10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '${_currentSettings?.charsPerLine ?? 32}',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppPallete.primary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isConnecting ? null : _testPrint,
              icon: _isConnecting 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.receipt_long_rounded),
              label: Text(_isConnecting ? 'Mencoba Menghubungkan...' : 'Cetak Test Receipt', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPallete.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
                shadowColor: AppPallete.primary.withAlpha(100),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptPreview() {
    final chars = _currentSettings?.charsPerLine ?? 32;
    final divider = '-' * chars;
    final storeSettingsState = context.read<StoreSettingsBloc>().state;
    String storeName = 'NAMA TOKO';
    String storeAddress = 'Alamat Toko';
    
    if (storeSettingsState is StoreSettingsLoaded) {
      storeName = storeSettingsState.storeSettings.storeName;
      storeAddress = storeSettingsState.storeSettings.storeAddress;
    }
    
    return Container(
      width: double.infinity,
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
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: const BoxDecoration(
              color: AppPallete.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Center(
              child: Text(
                'LIVE PREVIEW (${chars} Chars)',
                style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppPallete.textSecondary),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: IntrinsicWidth(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppPallete.divider.withAlpha(30)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _receiptLine(_formatCenter(storeName.toUpperCase(), chars), bold: true, center: true),
                        _receiptLine(_formatCenter(storeAddress, chars), center: true),
                        const SizedBox(height: 8),
                        _receiptText(divider, center: true),
                        _receiptLine(_formatCenter('STRUK PEMBAYARAN', chars), center: true),
                        _receiptText(divider, center: true),
                        const SizedBox(height: 8),
                        _receiptRow('1x ES KOPI SUSU GULA AREN SPESIAL', '18.000', chars),
                        _receiptRow('1x NASI GORENG SEAFOOD PEDAS SEKALI', '55.000', chars),
                        _receiptRow('2x TEH MANIS', '10.000', chars),
                        const SizedBox(height: 8),
                        _receiptText(divider, center: true),
                        _receiptRow('TOTAL', '83.000', chars, bold: true),
                        _receiptRow('TUNAI', '100.000', chars),
                        _receiptRow('KEMBALI', '17.000', chars),
                        const SizedBox(height: 16),
                        _receiptText(divider, center: true),
                        const SizedBox(height: 8),
                        _receiptLine(_formatCenter('TERIMA KASIH', chars), bold: true, center: true),
                        _receiptLine(_formatCenter('SILAHKAN DATANG KEMBALI', chars), center: true),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Paper tear effect
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              15,
              (index) => Container(
                width: 10,
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: AppPallete.divider.withAlpha(50),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatCenter(String text, int width) {
    return text.trim();
  }

  Widget _receiptRow(String left, String right, int width, {bool bold = false}) {
    final List<String> lines = [];
    final maxLeftWidth = width - right.length - 1;
    
    if (left.length <= maxLeftWidth) {
      final int spacesNeeded = (width - left.length - right.length).clamp(0, width);
      lines.add(left + (' ' * spacesNeeded) + right);
    } else {
      String remaining = left;
      while (remaining.length > width) {
        lines.add(remaining.substring(0, width));
        remaining = remaining.substring(width);
      }
      
      if (remaining.length <= maxLeftWidth) {
        final int spacesNeeded = (width - remaining.length - right.length).clamp(0, width);
        lines.add(remaining + (' ' * spacesNeeded) + right);
      } else {
        lines.add(remaining.padRight(width));
        final int spacesNeeded = (width - right.length).clamp(0, width);
        lines.add((' ' * spacesNeeded) + right);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) => _receiptText(line, bold: bold)).toList(),
    );
  }

  Widget _receiptText(String text, {bool bold = false, bool center = false}) {
    return Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      softWrap: false,
      overflow: TextOverflow.visible,
      style: TextStyle(
        fontFamily: 'Courier',
        fontSize: 13,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: Colors.black87,
        letterSpacing: 0,
        height: 1.2,
      ),
    );
  }

  Widget _receiptLine(String text, {bool bold = false, bool center = false}) {
    return _receiptText(text, bold: bold, center: center);
  }

  Widget _buildPresetButton(int value, String label) {
    final isSelected = _currentSettings?.charsPerLine == value;
    return Expanded(
      child: InkWell(
        onTap: () => _updateCharsPerLine(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppPallete.primary : AppPallete.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? AppPallete.primary : AppPallete.divider, width: 2),
            boxShadow: isSelected ? [BoxShadow(color: AppPallete.primary.withAlpha(40), blurRadius: 8, offset: const Offset(0, 4))] : [],
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : AppPallete.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tips Persiapan',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.blue.shade900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gunakan pratinjau di atas untuk memastikan teks tidak terpotong. Jika teks terlihat berantakan pada hasil cetak fisik, cobalah menurunkan nilai karakter per baris.',
                  style: GoogleFonts.outfit(fontSize: 12, color: Colors.blue.shade800, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
