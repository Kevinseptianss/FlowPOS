import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

Future<double> showOpeningBalanceDialog(
  BuildContext context, {
  required String cashierName,
}) async {
  final openingBalance = await showDialog<double>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: _OpeningBalanceDialog(cashierName: cashierName),
      );
    },
  );

  return openingBalance ?? 0;
}

class _OpeningBalanceDialog extends StatefulWidget {
  final String cashierName;

  const _OpeningBalanceDialog({required this.cashierName});

  @override
  State<_OpeningBalanceDialog> createState() => _OpeningBalanceDialogState();
}

class _OpeningBalanceDialogState extends State<_OpeningBalanceDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late final NumberFormat _currency;

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

  @override
  Widget build(BuildContext context) {
    final parsedAmount = _parseRupiah(_controller.text);

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      contentPadding: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Container(
        width: 440,
        decoration: BoxDecoration(
          color: AppPallete.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppPallete.primary, AppPallete.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppPallete.onPrimary.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.payments_rounded,
                          color: AppPallete.onPrimary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Buka Kasir',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppPallete.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Halo, ${widget.cashierName}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppPallete.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Input Modal Awal untuk memulai shift.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPallete.onPrimary.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppPallete.textPrimary,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Modal Awal',
                        hintText: 'Contoh: 250000',
                        prefixIcon: const Icon(
                          Icons.account_balance_wallet_rounded,
                        ),
                        filled: true,
                        fillColor: AppPallete.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        errorMaxLines: 2,
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        final amount = _parseRupiah(value ?? '');

                        if (amount <= 0) {
                          return 'Modal awal harus lebih dari Rp 0.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: parsedAmount > 0
                            ? AppPallete.success.withValues(alpha: 0.12)
                            : AppPallete.warning.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        parsedAmount > 0
                            ? 'Modal tersimpan: ${_currency.format(parsedAmount)}'
                            : 'Masukkan nominal untuk mengaktifkan shift.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppPallete.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPallete.primary,
                        foregroundColor: AppPallete.onPrimary,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      onPressed: () {
                        if (!(_formKey.currentState?.validate() ?? false)) {
                          return;
                        }

                        Navigator.of(context).pop(parsedAmount);
                      },
                      icon: const Icon(Icons.lock_open_rounded),
                      label: const Text('Simpan & Mulai Shift'),
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
  final currency = NumberFormat.currency(symbol: 'Rp ', decimalDigits: 0);
  final formatter = DateFormat('dd MMM yyyy, HH:mm');
  final shiftDuration = DateTime.now().difference(openedAt);
  final shiftHours = shiftDuration.inHours;
  final shiftMinutes = shiftDuration.inMinutes.remainder(60);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 420,
          decoration: BoxDecoration(
            color: AppPallete.surface,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppPallete.warning, AppPallete.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppPallete.onPrimary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.lock_clock_rounded,
                        color: AppPallete.onPrimary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Akhiri Shift Kasir',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  color: AppPallete.onPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pastikan semua transaksi sudah selesai.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppPallete.onPrimary.withValues(
                                    alpha: 0.9,
                                  ),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppPallete.warning.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppPallete.warning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: AppPallete.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Data shift disimpan lokal dan siap dikirim ke database.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppPallete.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppPallete.background,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        children: [
                          _ShiftInfoRow(
                            icon: Icons.account_balance_wallet_rounded,
                            label: 'Modal Awal',
                            value: currency.format(openingBalance),
                            valueColor: AppPallete.primary,
                          ),
                          const SizedBox(height: 10),
                          _ShiftInfoRow(
                            icon: Icons.play_circle_outline_rounded,
                            label: 'Mulai Shift',
                            value: formatter.format(openedAt),
                          ),
                          const SizedBox(height: 10),
                          _ShiftInfoRow(
                            icon: Icons.timelapse_rounded,
                            label: 'Durasi Shift',
                            value: '${shiftHours}j ${shiftMinutes}m',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(false),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(46),
                              side: BorderSide(
                                color: AppPallete.textPrimary.withValues(
                                  alpha: 0.24,
                                ),
                              ),
                            ),
                            child: const Text('Lanjut Shift'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppPallete.primary,
                              foregroundColor: AppPallete.onPrimary,
                              minimumSize: const Size.fromHeight(46),
                            ),
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(true),
                            icon: const Icon(Icons.check_circle_rounded),
                            label: const Text('Tutup Kasir'),
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
              color: AppPallete.textPrimary.withValues(alpha: 0.74),
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
