import 'dart:async';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/core/services/midtrans_service.dart';
import 'package:flow_pos/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:flow_pos/core/utils/currency_input_formatter.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:webview_flutter/webview_flutter.dart';

class QRISDialog extends StatefulWidget {
  final int total;
  final String orderId;
  final String serverKey;
  final bool isProduction;
  final String? initialQrString;
  final String? initialSnapUrl;
  final Function() onPaymentSuccess;

  const QRISDialog({
    super.key,
    required this.total,
    required this.orderId,
    required this.serverKey,
    this.isProduction = false,
    this.initialQrString,
    this.initialSnapUrl,
    required this.onPaymentSuccess,
  });

  @override
  State<QRISDialog> createState() => _QRISDialogState();
}

class _QRISDialogState extends State<QRISDialog> {
  late MidtransService _midtransService;
  String? _qrString;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _statusTimer;

  String? _currentOrderId;

  @override
  void initState() {
    super.initState();
    _currentOrderId = widget.orderId;
    _midtransService = MidtransService(
      serverKey: widget.serverKey,
      isProduction: widget.isProduction,
    );

    _checkCacheAndGenerate();
  }

  void _checkCacheAndGenerate() async {
    final box = serviceLocator<Box<String>>(instanceName: 'qris_cache');
    // Force a fresh link generation if we don't have a reliable initial state
    if (widget.initialQrString != null) {
      _qrString = widget.initialQrString;
      _isLoading = false;
      box.put(_currentOrderId!, _qrString!); // Sync cache
      _startStatusPolling();
    } else if (widget.initialSnapUrl != null) {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSnapFallback(url: widget.initialSnapUrl);
      });
    } else {
      // CLEAR CACHE for this ID to ensure we don't use an expired one
      await box.delete(_currentOrderId);
      _generateQRIS();
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _generateNewIDAndTryAgain() {
    setState(() {
      _currentOrderId = '${widget.orderId}-${DateTime.now().millisecondsSinceEpoch}';
      _qrString = null;
      _errorMessage = null;
      _isLoading = true;
    });
    _generateQRIS();
  }

  Future<void> _generateQRIS() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _midtransService.generateQris(
      orderId: _currentOrderId!,
      amount: widget.total,
    );

    if (mounted && result['success']) {
      setState(() {
        _qrString = result['qr_string'];
        _isLoading = false;
      });
      // Save to cache
      final box = serviceLocator<Box<String>>(instanceName: 'qris_cache');
      box.put(_currentOrderId!, _qrString!);
      _startStatusPolling();
    } else {
      // Robust Fallback: Try Snap URL if QRIS generation fails
      if (mounted) {
        _handleSnapFallback();
      }
    }
  }

  Future<void> _handleSnapFallback({String? url}) async {
    final String? finalUrl;

    if (url != null) {
      finalUrl = url;
    } else {
      final snapResult = await _midtransService.generateSnapUrl(
        orderId: _currentOrderId!,
        amount: widget.total,
      );
      if (snapResult['success']) {
        finalUrl = snapResult['redirect_url'];
      } else {
        setState(() {
          _errorMessage = snapResult['message'];
          _isLoading = false;
        });
        return;
      }
    }

    if (mounted && finalUrl != null) {
      Navigator.pop(context); // Close dialog
      showDialog(
        context: context,
        useRootNavigator: true, 
        barrierDismissible: false,
        builder: (context) => MidtransWebView(
          url: finalUrl!,
          orderId: _currentOrderId!,
          serverKey: widget.serverKey,
          isProduction: widget.isProduction,
          onSuccess: widget.onPaymentSuccess,
        ),
      );
    }
  }

  void _startStatusPolling() {
    _statusTimer?.cancel();
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final result = await _midtransService.checkTransactionStatus(
        _currentOrderId!,
      );
      if (result['success']) {
        final status = result['status'];
        if (status == 'settlement' || status == 'capture') {
          timer.cancel();
          widget.onPaymentSuccess();
        } else if (status == 'expire' || status == 'cancel' || status == 'deny') {
          timer.cancel();
          setState(() {
            _errorMessage = 'Transaksi telah $status. Silakan buat link baru.';
            _isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _checkManualStatus() async {
    setState(() => _isLoading = true);
    final result = await _midtransService.checkTransactionStatus(_currentOrderId!);
    
    if (mounted) {
      if (result['success']) {
        final status = result['status'];
        if (status == 'settlement' || status == 'capture') {
          showSnackbar(context, 'Pembayaran Berhasil!');
          widget.onPaymentSuccess();
          Navigator.pop(context);
        } else {
          setState(() => _isLoading = false);
          showSnackbar(context, 'Status: $status. Belum ada pembayaran terdeteksi.');
        }
      } else {
        setState(() => _isLoading = false);
        showSnackbar(context, 'Gagal mengecek status. Coba lagi nanti.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pembayaran QRIS',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatRupiah(widget.total),
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppPallete.primary,
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading)
            const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            SizedBox(
              height: 200,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(_errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _generateNewIDAndTryAgain,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Buat Link Pembayaran Baru'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppPallete.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          else if (_qrString != null)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppPallete.divider),
                  ),
                  child: QrImageView(
                    data: _qrString!,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Silakan scan kode QR di atas untuk membayar.'),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Menunggu pembayaran...',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _checkManualStatus,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Cek Status Pembayaran'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPallete.primary,
                    side: const BorderSide(color: AppPallete.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Batalkan',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TransferBankDialog extends StatelessWidget {
  final int total;
  final String bankName;
  final String accountNumber;
  final Function() onConfirm;

  const TransferBankDialog({
    super.key,
    required this.total,
    required this.bankName,
    required this.accountNumber,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Transfer Bank',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppPallete.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('Silakan transfer ke rekening berikut:'),
                const SizedBox(height: 16),
                Text(
                  bankName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  accountNumber,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Total: ${formatRupiah(total)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppPallete.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPallete.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Konfirmasi Sudah Bayar',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class CardPaymentDialog extends StatelessWidget {
  final int total;
  final Function() onConfirm;

  const CardPaymentDialog({
    super.key,
    required this.total,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pembayaran Kartu',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Icon(
            Icons.credit_card_rounded,
            size: 64,
            color: AppPallete.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Silakan proses pembayaran di mesin EDC sebesar:',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppPallete.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            formatRupiah(total),
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppPallete.primary,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPallete.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Sudah Diproses di EDC',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class CashPaymentDialog extends StatefulWidget {
  final int total;
  final Function(int) onConfirmPayment;

  const CashPaymentDialog({
    super.key,
    required this.total,
    required this.onConfirmPayment,
  });

  @override
  State<CashPaymentDialog> createState() => _CashPaymentDialogState();
}

class _CashPaymentDialogState extends State<CashPaymentDialog> {
  late final TextEditingController amountController;
  int change = -1; // Initial state

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isValidPayment = change >= 0 && amountController.text.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppPallete.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Text(
                  'Pembayaran Tunai',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tagihan: ${formatRupiah(widget.total)}',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: AppPallete.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: AppPallete.primary,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    prefixText: 'Rp ',
                    prefixStyle: GoogleFonts.outfit(
                      fontSize: 24,
                      color: AppPallete.textSecondary,
                    ),
                    border: InputBorder.none,
                  ),
                  inputFormatters: [CurrencyInputFormatter()],
                  onChanged: (value) {
                    final amountText = value.replaceAll(RegExp(r'[^0-9]'), '');
                    final amount = int.tryParse(amountText) ?? 0;
                    setState(() => change = amount - widget.total);
                  },
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildShortcut(widget.total, 'Uang Pas'),
                    _buildShortcut(20000, '20k'),
                    _buildShortcut(50000, '50k'),
                    _buildShortcut(100000, '100k'),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: change >= 0
                        ? AppPallete.primary.withAlpha(10)
                        : AppPallete.error.withAlpha(10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kembalian',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppPallete.textSecondary,
                        ),
                      ),
                      Text(
                        change < 0
                            ? 'Kurang ${formatRupiah(change.abs())}'
                            : formatRupiah(change),
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: change >= 0
                              ? AppPallete.primary
                              : AppPallete.error,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Batal',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: isValidPayment
                            ? () {
                                final amountText = amountController.text
                                    .replaceAll(RegExp(r'[^0-9]'), '');
                                final amount = int.tryParse(amountText) ?? 0;
                                Navigator.pop(context);
                                widget.onConfirmPayment(amount);
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPallete.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Proses Bayar',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcut(int amount, String label) {
    return InkWell(
      onTap: () {
        final formatter = NumberFormat.decimalPattern('id');
        final formatted = formatter.format(amount);
        amountController.text = formatted;
        setState(() => change = amount - widget.total);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppPallete.divider),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      ),
    );
  }
}

class MidtransWebView extends StatefulWidget {
  final String url;
  final String orderId;
  final String serverKey;
  final bool isProduction;
  final VoidCallback onSuccess;
  final Function(String)? onFailure;
  final VoidCallback? onCancel;
  final Function(String)? onUrlChange;

  const MidtransWebView({
    super.key,
    required this.url,
    required this.orderId,
    required this.serverKey,
    this.isProduction = false,
    required this.onSuccess,
    this.onFailure,
    this.onCancel,
    this.onUrlChange,
  });

  @override
  State<MidtransWebView> createState() => _MidtransWebViewState();
}

class _MidtransWebViewState extends State<MidtransWebView> {
  late final WebViewController _controller;
  late final MidtransService _midtransService;
  bool _isLoading = true;
  bool _isCheckingStatus = false;

  @override
  void initState() {
    super.initState();
    _midtransService = MidtransService(
      serverKey: widget.serverKey,
      isProduction: widget.isProduction,
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            if (widget.onUrlChange != null) {
              widget.onUrlChange!(url);
            }
            if (url.contains('/finish') || url.contains('/success')) {
              debugPrint('--- [WEBVIEW] Transaction SUCCESS detected ---');
              widget.onSuccess();
              // Removed auto-pop: wait for manual closure
            } else if (url.contains('/failed') || url.contains('/error')) {
              debugPrint('--- [WEBVIEW] Transaction FAILED detected ---');
              if (widget.onFailure != null) widget.onFailure!(url);
              // Removed auto-pop: wait for manual closure
            } else if (url.contains('/cancel')) {
              debugPrint('--- [WEBVIEW] Transaction CANCELLED detected ---');
              if (widget.onCancel != null) widget.onCancel!();
              // Removed auto-pop: wait for manual closure
            }
          },
          onWebResourceError: (WebResourceError error) {},
          onNavigationRequest: (NavigationRequest request) {
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _checkManualStatus() async {
    setState(() => _isCheckingStatus = true);
    final result = await _midtransService.checkTransactionStatus(widget.orderId);
    
    if (mounted) {
      setState(() => _isCheckingStatus = false);
      if (result['success']) {
        final status = result['status'];
        if (status == 'settlement' || status == 'capture') {
          showSnackbar(context, 'Pembayaran Berhasil Diverifikasi!');
          widget.onSuccess();
          Navigator.pop(context);
        } else {
          showSnackbar(context, 'Status: $status. Menunggu pembayaran masuk.');
        }
      } else {
        showSnackbar(context, 'Gagal verifikasi. Periksa koneksi atau coba lagi.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pembayaran Midtrans',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isCheckingStatus || _isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppPallete.primary),
                  ),
                ),
              ),
            )
          else
            TextButton.icon(
              onPressed: _checkManualStatus,
              icon: const Icon(Icons.verified_user_rounded, size: 18),
              label: const Text('Verifikasi'),
              style: TextButton.styleFrom(
                foregroundColor: AppPallete.primary,
              ),
            ),
        ],
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
