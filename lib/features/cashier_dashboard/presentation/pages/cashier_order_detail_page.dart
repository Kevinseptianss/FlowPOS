import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/services/thermal_receipt_printer_service.dart';
import 'package:flow_pos/core/utils/datetime_formatter.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:flow_pos/features/store_settings/presentation/bloc/store_settings_bloc.dart';
import 'package:flow_pos/init_dependencies.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/payment_dialogs.dart';
import 'package:flow_pos/core/services/midtrans_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class CashierOrderDetailPage extends StatefulWidget {
  final OrderEntity order;

  const CashierOrderDetailPage({super.key, required this.order});

  static MaterialPageRoute route(OrderEntity order) => MaterialPageRoute(
    builder: (context) => CashierOrderDetailPage(order: order),
  );

  @override
  State<CashierOrderDetailPage> createState() => _CashierOrderDetailPageState();
}

class _CashierOrderDetailPageState extends State<CashierOrderDetailPage> {
  late OrderEntity _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  Future<void> _onPrintPressed(BuildContext context) async {
    final printerService = serviceLocator<ThermalReceiptPrinterService>();
    final storeSettings = _resolveStoreSettings(context);
    final cashierName = _resolveCashierName(context);

    try {
      final connected = await printerService.isConnected;
      if (!context.mounted) return;

      if (!connected) {
        final selectedDevice = await printerService.selectDevice(
          context: context,
        );
        if (selectedDevice == null) return;

        await printerService.connect(macAddress: selectedDevice.macAddress);
        if (!context.mounted) return;
      }

      await printerService.printOrderReceipt(
        context: context,
        order: _currentOrder,
        storeSettings: storeSettings,
        cashierName: cashierName,
      );

      if (!context.mounted) return;
      showSnackbar(context, 'Struk berhasil dicetak.');
    } catch (error) {
      if (!context.mounted) return;
      final message = error is Exception
          ? error.toString().replaceFirst('Exception: ', '')
          : 'Gagal mencetak struk.';
      showSnackbar(context, message);
    }
  }

  StoreSettings _resolveStoreSettings(BuildContext context) {
    final state = context.read<StoreSettingsBloc>().state;
    if (state is StoreSettingsLoaded) return state.storeSettings;
    if (state is StoreSettingsUpdated) return state.storeSettings;
    return const StoreSettings.zero();
  }

  String _resolveCashierName(BuildContext context) {
    final userState = context.read<UserBloc>().state;
    if (userState is UserLoggedIn) return userState.user.name;
    return 'Cashier';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrderSettled && state.orderId == _currentOrder.id) {
          context.read<OrderBloc>().add(GetAllOrdersEvent());
        } else if (state is OrdersLoaded) {
          final updatedOrder = state.orders.firstWhere(
            (o) => o.id == _currentOrder.id,
            orElse: () => _currentOrder,
          );
          if (updatedOrder.status != _currentOrder.status) {
            setState(() {
              _currentOrder = updatedOrder;
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppPallete.background,
        appBar: AppBar(
          title: Text(
            'Rincian Transaksi',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: AppPallete.textPrimary,
            ),
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: AppPallete.textPrimary),
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                children: [
                  _ModernHeroDetailCard(order: _currentOrder),
                  const SizedBox(height: 20),
                  _ReceiptContentCard(
                    order: _currentOrder,
                    onSettle: () {
                      if (_currentOrder.paymentLink != null) {
                        final settingsState = context.read<StoreSettingsBloc>().state;
                        if (settingsState is StoreSettingsLoaded) {
                          final settings = settingsState.storeSettings;
                          _triggerQRISPayment(
                            context,
                            _currentOrder,
                            settings.midtransServerKey ?? '',
                            !settings.isMidtransSandbox,
                            () => {},
                          );
                        }
                      } else {
                        _showSettleDialog(context, _currentOrder);
                      }
                    },
                    onCheckStatus: () {
                      final settingsState = context.read<StoreSettingsBloc>().state;
                      if (settingsState is StoreSettingsLoaded) {
                        final settings = settingsState.storeSettings;
                        _triggerStatusCheck(
                          context,
                          _currentOrder,
                          settings.midtransServerKey ?? '',
                          !settings.isMidtransSandbox,
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: _currentOrder.status == 'VOIDED' || _currentOrder.status == 'PAID' || _currentOrder.status == 'settlement' || _currentOrder.status == 'SETTLEMENT'
            ? (_currentOrder.status == 'PAID' || _currentOrder.status == 'settlement' || _currentOrder.status == 'SETTLEMENT'
                ? _ModernActionBar(
                    order: _currentOrder,
                    onPrint: () => _onPrintPressed(context),
                    onSettle: () {}, // Not needed for PAID
                    onVoid: () => _showVoidConfirmation(context, _currentOrder),
                  )
                : null)
            : _ModernActionBar(
                order: _currentOrder,
                onPrint: () => _onPrintPressed(context),
                onSettle: () {
                  if (_currentOrder.paymentLink != null) {
                    final settingsState = context.read<StoreSettingsBloc>().state;
                    if (settingsState is StoreSettingsLoaded) {
                      final settings = settingsState.storeSettings;
                      _triggerQRISPayment(
                        context,
                        _currentOrder,
                        settings.midtransServerKey ?? '',
                        !settings.isMidtransSandbox,
                        () => {},
                      );
                    }
                  } else {
                    _showSettleDialog(context, _currentOrder);
                  }
                },
                onVoid: () => _showVoidConfirmation(context, _currentOrder),
              ),
      ),
    );
  }

  void _showVoidConfirmation(BuildContext context, OrderEntity order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppPallete.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'Batalkan Pesanan?',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: AppPallete.error,
          ),
        ),
        content: Text(
          'Seluruh pesanan ini akan dibatalkan dan tidak akan masuk dalam laporan pendapatan.',
          style: GoogleFonts.outfit(color: AppPallete.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Kembali',
              style: GoogleFonts.outfit(
                color: AppPallete.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<OrderBloc>().add(VoidOrderEvent(orderId: order.id));
              Navigator.pop(context); // Go back to history
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppPallete.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Ya, Batalkan',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSettleDialog(BuildContext context, OrderEntity order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SettlePaymentSheet(
        order: order,
        onSuccess: () {
          Navigator.pop(context); // Close detail page
        },
      ),
    );
  }
} // End of CashierOrderDetailPage

Future<void> _triggerStatusCheck(BuildContext context, OrderEntity order, String serverKey, bool isProduction) async {
  if (serverKey.isEmpty) {
    showSnackbar(context, 'Konfigurasi Midtrans belum lengkap');
    return;
  }

  final midtransService = MidtransService(serverKey: serverKey, isProduction: isProduction);
  
  // Potential order IDs used in generating payments
  final orderIdsToCheck = [
    order.orderNumber,
    // Add variations if needed, but usually we use orderNumber for resumed links
  ];

  showSnackbar(context, 'Mengecek status pembayaran...');

  bool foundSuccess = false;
  String lastStatus = '';

  for (final id in orderIdsToCheck) {
    final result = await midtransService.checkTransactionStatus(id);
    if (result['success']) {
      final status = result['status'];
      lastStatus = status;
      if (status == 'settlement' || status == 'capture') {
        foundSuccess = true;
        break;
      }
    }
  }

  if (!context.mounted) return;

  if (foundSuccess) {
    showSnackbar(context, 'Pembayaran Berhasil Diverifikasi!');
    context.read<OrderBloc>().add(
      SettleOrderEvent(
        orderId: order.id,
        method: 'QRIS', // Assuming QRIS for these auto-checks
        amountPaid: order.total,
        amountDue: order.total,
        changeGiven: 0,
      ),
    );
  } else {
    final msg = lastStatus.isNotEmpty 
        ? 'Status: $lastStatus. Belum ada pembayaran.'
        : 'Tidak ada transaksi ditemukan untuk pesanan ini.';
    showSnackbar(context, msg);
  }
}

void _triggerCashPayment(BuildContext context, OrderEntity order, VoidCallback onSuccess) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CashPaymentDialog(
      total: order.total,
      onConfirmPayment: (amountPaid) {
        context.read<OrderBloc>().add(
          SettleOrderEvent(
            orderId: order.id,
            method: 'CASH',
            amountPaid: amountPaid,
            amountDue: order.total,
            changeGiven: amountPaid - order.total,
          ),
        );
        Navigator.pop(context);
        onSuccess();
      },
    ),
  );
}

void _triggerQRISPayment(BuildContext context, OrderEntity order, String serverKey, bool isProduction, VoidCallback onSuccess) {
  if (serverKey.isEmpty) {
    showSnackbar(context, 'Konfigurasi QRIS belum lengkap');
    return;
  }
  showModalBottomSheet(
    context: context,
    useRootNavigator: true, 
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => QRISDialog(
      total: order.total,
      orderId: order.paymentLink != null 
          ? order.orderNumber 
          : '${order.orderNumber}-${DateTime.now().millisecondsSinceEpoch}', 
      serverKey: serverKey,
      isProduction: isProduction,
      initialSnapUrl: order.paymentLink,
      onPaymentSuccess: () {
        context.read<OrderBloc>().add(
          SettleOrderEvent(
            orderId: order.id,
            method: 'QRIS',
            amountPaid: order.total,
            amountDue: order.total,
            changeGiven: 0,
          ),
        );
        Navigator.pop(context);
        onSuccess();
      },
    ),
  );
}

void _triggerTransferPayment(BuildContext context, OrderEntity order, String bank, String number, VoidCallback onSuccess) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TransferBankDialog(
      total: order.total,
      bankName: bank,
      accountNumber: number,
      onConfirm: () {
        context.read<OrderBloc>().add(
          SettleOrderEvent(
            orderId: order.id,
            method: 'TRANSFER',
            amountPaid: order.total,
            amountDue: order.total,
            changeGiven: 0,
          ),
        );
        Navigator.pop(context);
        onSuccess();
      },
    ),
  );
}

void _triggerCardPayment(BuildContext context, OrderEntity order, VoidCallback onSuccess) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CardPaymentDialog(
      total: order.total,
      onConfirm: () {
        context.read<OrderBloc>().add(
          SettleOrderEvent(
            orderId: order.id,
            method: 'CARD',
            amountPaid: order.total,
            amountDue: order.total,
            changeGiven: 0,
          ),
        );
        Navigator.pop(context);
        onSuccess();
      },
    ),
  );
}

class _SettlePaymentSheet extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onSuccess;

  const _SettlePaymentSheet({required this.order, required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoreSettingsBloc, StoreSettingsState>(
      builder: (context, settingsState) {
        final settings = settingsState is StoreSettingsLoaded
            ? settingsState.storeSettings
            : const StoreSettings.zero();

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
                'Selesaikan Pembayaran',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Meja ${order.tableNumber} - ${formatRupiah(order.total)}',
                style: GoogleFonts.outfit(color: AppPallete.textSecondary),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  if (settings.isCashEnabled)
                    _PaymentOptionButton(
                      label: 'TUNAI',
                      icon: Icons.payments_rounded,
                      color: AppPallete.primary,
                      onPressed: () => _showCashDialog(context),
                    ),
                  if (settings.isQrisEnabled)
                    _PaymentOptionButton(
                      label: 'QRIS',
                      icon: Icons.qr_code_scanner_rounded,
                      color: Colors.blue,
                      onPressed: () => _showQRISDialog(
                        context,
                        settings.midtransServerKey ?? '',
                        !settings.isMidtransSandbox,
                      ),
                    ),
                  if (settings.isTransferEnabled)
                    _PaymentOptionButton(
                      label: 'TRANSFER',
                      icon: Icons.account_balance_rounded,
                      color: Colors.teal,
                      onPressed: () => _showTransferDialog(
                        context,
                        settings.bankName ?? '-',
                        settings.bankAccountNumber ?? '-',
                      ),
                    ),
                  if (settings.isCardEnabled)
                    _PaymentOptionButton(
                      label: 'KARTU',
                      icon: Icons.credit_card_rounded,
                      color: Colors.orange,
                      onPressed: () => _showCardDialog(context),
                    ),
                ],
              ),
              const SizedBox(height: 32),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal', style: TextStyle(color: Colors.red)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showCashDialog(BuildContext context) {
    _triggerCashPayment(context, order, onSuccess);
  }

  void _showQRISDialog(BuildContext context, String serverKey, bool isProduction) {
    _triggerQRISPayment(context, order, serverKey, isProduction, onSuccess);
  }

  void _showTransferDialog(BuildContext context, String bank, String number) {
    _triggerTransferPayment(context, order, bank, number, onSuccess);
  }

  void _showCardDialog(BuildContext context) {
    _triggerCardPayment(context, order, onSuccess);
  }
}

class _PaymentOptionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _PaymentOptionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 100,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withAlpha(15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withAlpha(40), width: 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModernHeroDetailCard extends StatelessWidget {
  final OrderEntity order;

  const _ModernHeroDetailCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPallete.primary, AppPallete.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppPallete.primary.withAlpha(50),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _ModernStatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            DatetimeFormatter.formatDateYear(order.createdAt),
            style: GoogleFonts.outfit(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ModernPill(
                icon: Icons.table_restaurant_rounded,
                label: order.tableNumber == 0
                    ? 'Takeaway'
                    : 'Meja ${order.tableNumber}',
              ),
              if (order.customerName != null && order.customerName!.isNotEmpty)
                _ModernPill(
                  icon: Icons.person_rounded,
                  label: order.customerName!,
                ),
              _ModernPill(
                icon: Icons.shopping_bag_rounded,
                label: '${order.items.length} Item',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModernStatusBadge extends StatelessWidget {
  final String status;
  const _ModernStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final bool isPaid = status == 'PAID' || status == 'TERBAYAR';
    final bool isVoided = status == 'VOIDED';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isVoided
            ? Colors.red.withAlpha(40)
            : (isPaid
                  ? Colors.green.withAlpha(40)
                  : Colors.orange.withAlpha(40)),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isVoided
              ? Colors.red.withAlpha(60)
              : (isPaid
                    ? Colors.green.withAlpha(60)
                    : Colors.orange.withAlpha(60)),
        ),
      ),
      child: Text(
        isVoided ? 'DIBATALKAN' : (isPaid ? 'TERBAYAR' : 'PENDING'),
        style: GoogleFonts.outfit(
          color: isVoided
              ? Colors.redAccent
              : (isPaid ? Colors.white : Colors.orangeAccent),
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ModernPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ModernPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptContentCard extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onSettle;
  final VoidCallback onCheckStatus;
  const _ReceiptContentCard({
    required this.order,
    required this.onSettle,
    required this.onCheckStatus,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Detail Pembayaran',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: AppPallete.primary,
              ),
            ),
          ),
          if (order.status == 'UNPAID')
            _buildPendingPrompt()
          else if (order.payment == null)
            const SizedBox.shrink()
          else
            _buildPaymentSummary(),

          _buildDashedDivider(),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daftar Pesanan',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppPallete.primary,
                  ),
                ),
                const SizedBox(height: 20),
                ...order.items.asMap().entries.map(
                  (entry) =>
                      _ModernItemTile(index: entry.key + 1, item: entry.value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingPrompt() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withAlpha(20),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Menunggu Pembayaran',
                style: GoogleFonts.outfit(
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Column(
              children: [
                ElevatedButton(
                  onPressed: onSettle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    'Bayar Sekarang',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onCheckStatus,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  child: Text(
                    'Cek Status',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.orange[900],
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentSummary() {
    final p = order.payment!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          _ModernDetailRow(
            label: 'Metode Pembayaran',
            value: p.method,
            isHeader: true,
          ),
          _ModernDetailRow(
            label: 'Total Pesanan',
            value: formatRupiah(p.amountDue),
          ),
          _ModernDetailRow(
            label: 'Uang Diterima',
            value: formatRupiah(p.amountPaid),
          ),
          _ModernDetailRow(
            label: 'Kembalian',
            value: formatRupiah(p.changeGiven),
            isHighlight: true,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildDashedDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: List.generate(
          30,
          (index) => Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 1,
              color: AppPallete.divider.withAlpha(100),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModernDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;
  final bool isHeader;

  const _ModernDetailRow({
    required this.label,
    required this.value,
    this.isHighlight = false,
    this.isHeader = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: isHeader
                  ? AppPallete.textPrimary
                  : AppPallete.textSecondary,
              fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: isHighlight ? AppPallete.primary : AppPallete.textPrimary,
              fontWeight: isHighlight || isHeader
                  ? FontWeight.w900
                  : FontWeight.w700,
              fontSize: isHighlight ? 18 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernItemTile extends StatelessWidget {
  final int index;
  final OrderItem item;

  const _ModernItemTile({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppPallete.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$index',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: AppPallete.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.menuName,
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: item.isDeleted
                              ? AppPallete.textSecondary
                              : AppPallete.textPrimary,
                          decoration: item.isDeleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    Text(
                      formatRupiah(item.unitPrice * item.quantity),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppPallete.primary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${item.quantity} x ${formatRupiah(item.unitPrice)}',
                  style: GoogleFonts.outfit(
                    color: AppPallete.textSecondary,
                    fontSize: 13,
                  ),
                ),
                if (item.modifierSnapshot != null &&
                    item.modifierSnapshot!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      item.modifierSnapshot!,
                      style: GoogleFonts.outfit(
                        color: AppPallete.primary.withAlpha(180),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                if (item.isDeleted) _buildCanceledBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCanceledBadge() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'DIBATALKAN',
        style: GoogleFonts.outfit(
          color: Colors.red,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ModernActionBar extends StatelessWidget {
  final OrderEntity order;
  final VoidCallback onPrint;
  final VoidCallback onSettle;
  final VoidCallback onVoid;

  const _ModernActionBar({
    required this.order,
    required this.onPrint,
    required this.onSettle,
    required this.onVoid,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          _ActionButton(
            onPressed: onVoid,
            icon: Icons.delete_outline_rounded,
            label: '',
            color: AppPallete.error,
            isOutline: true,
            isIconOnly: true,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              onPressed: onPrint,
              icon: Icons.print_rounded,
              label: 'Cetak',
              color: AppPallete.primary,
              isOutline: true,
            ),
          ),
          if (order.status == 'UNPAID') ...[
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                onPressed: onSettle,
                icon: Icons.check_circle_rounded,
                label: 'Bayar',
                color: AppPallete.success,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool isOutline;
  final bool isIconOnly;

  const _ActionButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    this.isOutline = false,
    this.isIconOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isIconOnly) {
      return SizedBox(
        height: 56,
        width: 56,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            padding: EdgeInsets.zero,
            side: BorderSide(color: color.withAlpha(80), width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: Icon(icon, size: 24),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: isOutline
          ? OutlinedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(
                label,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color, width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              icon: Icon(icon, size: 20),
              label: Text(
                label,
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
    );
  }
}
