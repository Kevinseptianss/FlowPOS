import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:intl/intl.dart';

Future<Map<String, dynamic>?> showOpenShiftDialog(
  BuildContext context, {
  required String cashierName,
}) async {
  final result = await showGeneralDialog<Map<String, dynamic>>(
    context: context,
    barrierDismissible: false,
    pageBuilder: (context, animation, secondaryAnimation) => const SizedBox(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
      return ScaleTransition(
        scale: curve,
        child: FadeTransition(
          opacity: animation,
          child: _OpenShiftDialog(cashierName: cashierName),
        ),
      );
    },
  );

  return result;
}

class _OpenShiftDialog extends StatefulWidget {
  final String cashierName;

  const _OpenShiftDialog({required this.cashierName});

  @override
  State<_OpenShiftDialog> createState() => _OpenShiftDialogState();
}

class _OpenShiftDialogState extends State<_OpenShiftDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late final NumberFormat _currency;

  final List<double> _quickAmounts = [50000, 100000, 250000, 500000];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _currency = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addAmount(double amount) {
    setState(() {
      _controller.text = amount.toInt().toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final parsedAmount = _parseRupiah(_controller.text);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 460,
        decoration: BoxDecoration(
          color: AppPallete.surface,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppPallete.primary, AppPallete.primaryDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.rocket_launch_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Mulai Shift Baru',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Halo ${widget.cashierName}, masukkan modal awal di laci kasir untuk mulai berjualan.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                              height: 1.5,
                            ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: -20,
                  top: -20,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ],
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Modal Awal (Cash in Drawer)',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppPallete.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppPallete.primary,
                          ),
                      decoration: InputDecoration(
                        prefixText: 'Rp ',
                        prefixStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppPallete.primary.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w800,
                            ),
                        hintText: '0',
                        hintStyle: TextStyle(color: AppPallete.divider),
                        filled: true,
                        fillColor: AppPallete.background,
                        contentPadding: const EdgeInsets.symmetric(vertical: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),

                    // Quick Amounts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: _quickAmounts.map((amount) {
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: amount == _quickAmounts.last ? 0 : 8,
                            ),
                            child: InkWell(
                              onTap: () => _addAmount(amount),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppPallete.divider,
                                    width: 1.5,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _currency.format(amount).replaceAll('Rp ', ''),
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppPallete.textPrimary,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop({'action': 'skip'});
                            },
                            child: Text(
                              'Nanti Saja',
                              style: TextStyle(
                                color: AppPallete.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPallete.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 4,
                              shadowColor: AppPallete.primary.withValues(alpha: 0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            onPressed: () {
                              if (parsedAmount <= 0) {
                                showSnackbar(context, 'Masukkan modal awal terlebih dahulu');
                                return;
                              }
                              Navigator.of(context).pop({
                                'action': 'open',
                                'openingBalance': parsedAmount,
                              });
                            },
                            child: const Text(
                              'Buka Kasir',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<bool> showCloseShiftDialog(
  BuildContext context, {
  required double openingBalance,
  required DateTime openedAt,
}) async {
  const wibOffset = Duration(hours: 7);
  final currency = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);
  final formatter = DateFormat('dd MMM yyyy, HH:mm');
  final openedAtWib = openedAt.toUtc().add(wibOffset);
  final nowWib = DateTime.now().toUtc().add(wibOffset);
  final shiftDuration = nowWib.difference(openedAtWib);
  final shiftHours = shiftDuration.inHours;
  final shiftMinutes = shiftDuration.inMinutes.remainder(60);

  final confirmed = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close Shift',
    pageBuilder: (context, anim1, anim2) => const SizedBox(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: animation,
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
              width: 440,
              decoration: BoxDecoration(
                color: AppPallete.surface,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppPallete.warning, AppPallete.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.lock_clock_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Akhiri Shift Kasir',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Konfirmasi untuk menutup sesi hari ini.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white.withValues(alpha: 0.8),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Summary Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppPallete.background,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppPallete.divider),
                          ),
                          child: Column(
                            children: [
                              _ShiftInfoRow(
                                icon: Icons.account_balance_wallet_rounded,
                                label: 'Modal Awal',
                                value: currency.format(openingBalance),
                                valueColor: AppPallete.primary,
                              ),
                              const Divider(height: 24),
                              _ShiftInfoRow(
                                icon: Icons.play_circle_outline_rounded,
                                label: 'Waktu Mulai',
                                value: formatter.format(openedAtWib),
                              ),
                              const SizedBox(height: 12),
                              _ShiftInfoRow(
                                icon: Icons.timelapse_rounded,
                                label: 'Durasi Kerja',
                                value: '${shiftHours}j ${shiftMinutes}m',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                ),
                                onPressed: () => Navigator.of(context).pop(false),
                                child: Text(
                                  'Batal',
                                  style: TextStyle(
                                    color: AppPallete.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppPallete.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text(
                                  'Tutup Kasir Sekarang',
                                  style: TextStyle(fontWeight: FontWeight.w800),
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
            ),
          ),
        ),
      );
    },
  );

  return confirmed ?? false;
}

class _ShiftInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _ShiftInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppPallete.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: AppPallete.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppPallete.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? AppPallete.textPrimary,
          ),
        ),
      ],
    );
  }
}

double _parseRupiah(String input) {
  final normalized = input.replaceAll(RegExp(r'[^0-9]'), '');

  if (normalized.isEmpty) {
    return 0;
  }

  return double.tryParse(normalized) ?? 0;
}
