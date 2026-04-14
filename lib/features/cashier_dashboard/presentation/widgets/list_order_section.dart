import 'dart:async';
import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/services/cashier_shift_local_service.dart';
import 'package:flow_pos/core/services/midtrans_service.dart';
import 'package:flow_pos/core/services/thermal_receipt_printer_service.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/cashier_dashboard/domain/entities/cart.dart';
import 'package:flow_pos/features/cashier_dashboard/domain/entities/selected_modifier.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/cart_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/table_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/summary_row.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:flow_pos/features/store_settings/domain/entities/store_settings.dart';
import 'package:flow_pos/features/store_settings/presentation/bloc/store_settings_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/payment_dialogs.dart';
import 'package:flow_pos/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class ListOrderSection extends StatelessWidget {
  final bool isMobileCheckoutFlow;
  final bool isPayoutMode;

  const ListOrderSection({
    super.key,
    this.isMobileCheckoutFlow = false,
    this.isPayoutMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, orderState) async {
        if (orderState is OrderCreated) {
          await _handleOrderCreated(context, orderState.order);
        } else if (orderState is OrderFailure) {
          showSnackbar(context, orderState.message);
        }
      },
      child: BlocBuilder<StoreSettingsBloc, StoreSettingsState>(
        builder: (context, settingsState) {
          final storeSettings = settingsState is StoreSettingsLoaded
              ? settingsState.storeSettings
              : const StoreSettings.zero();

          return BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartEmpty) {
                return Container(
                  color: AppPallete.surface,
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_basket_outlined,
                          size: 64,
                          color: AppPallete.divider,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Keranjang Kosong',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppPallete.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (state is CartLoaded) {
                final double taxRate = storeSettings.taxPercentage;
                final double serviceChargeRate =
                    storeSettings.serviceChargePercentage;

                final int subtotal = state.totalAmount;
                final int tax = _calculateCharge(subtotal, taxRate);
                final int serviceCharge = _calculateCharge(
                  subtotal,
                  serviceChargeRate,
                );
                final int total = subtotal + tax + serviceCharge;

                return Container(
                  color: AppPallete.surface,
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.shopping_cart_rounded,
                                color: AppPallete.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Pesanan Saya',
                                style: GoogleFonts.outfit(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppPallete.textPrimary,
                                ),
                              ),
                              const Spacer(),
                              BlocBuilder<TableBloc, TableState>(
                                builder: (context, tableState) {
                                  final isTakeaway =
                                      tableState.selectedTableNumber == 0;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isTakeaway
                                          ? AppPallete.secondary.withAlpha(30)
                                          : AppPallete.primary.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isTakeaway
                                            ? AppPallete.secondary.withAlpha(
                                                100,
                                              )
                                            : AppPallete.primary.withAlpha(50),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isTakeaway
                                              ? Icons.local_mall_rounded
                                              : Icons.chair_rounded,
                                          size: 13,
                                          color: isTakeaway
                                              ? AppPallete.secondary
                                              : AppPallete.primary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isTakeaway
                                              ? 'Takeaway'
                                              : 'Table ${tableState.selectedTableNumber}',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: isTakeaway
                                                ? AppPallete.secondary
                                                : AppPallete.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppPallete.textSecondary.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${state.items.length} Item',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppPallete.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Expanded(
                            child: ListView.builder(
                              itemCount: state.items.length,
                              itemBuilder: (context, index) {
                                final item = state.items[index];
                                return _OrderItemTile(
                                  cartItem: item,
                                  onQuantityChanged: (newQuantity) {
                                    context.read<CartBloc>().add(
                                      UpdateCartItemQuantityEvent(
                                        item.id,
                                        newQuantity,
                                      ),
                                    );
                                  },
                                  onRemove: () {
                                    context.read<CartBloc>().add(
                                      RemoveFromCartEvent(item.id),
                                    );
                                  },
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppPallete.background,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Column(
                              children: [
                                SummaryRow(label: 'Subtotal', value: subtotal),
                                SummaryRow(
                                  label:
                                      'Pajak (${_formatPercentage(taxRate)}%)',
                                  value: tax,
                                ),
                                SummaryRow(
                                  label:
                                      'Layanan (${_formatPercentage(serviceChargeRate)}%)',
                                  value: serviceCharge,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(height: 1),
                                ),
                                SummaryRow(
                                  label: 'Total Tagihan',
                                  value: total,
                                  isTotal: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          BlocBuilder<OrderBloc, OrderState>(
                            builder: (context, orderState) {
                              if (orderState is OrderLoading) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final userState = context.watch<UserBloc>().state;
                              final userId = userState is UserLoggedIn
                                  ? userState.user.id
                                  : '';
                              final shiftLocalService =
                                  serviceLocator<CashierShiftLocalService>();
                              final isSkipped = shiftLocalService
                                  .isShiftSkipped(userId);

                              return Column(
                                children: [
                                  BlocBuilder<TableBloc, TableState>(
                                    builder: (context, tableState) {
                                      final selectedTable =
                                          tableState.selectedTableNumber;
                                      final isDineIn = selectedTable > 0;

                                      // Show "Simpan Meja" IF:
                                      // 1. It's Dine-In AND we are NOT in Payout Mode
                                      if (isDineIn && !isPayoutMode) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: ElevatedButton(
                                            onPressed: isSkipped
                                                ? null
                                                : () async {
                                                    final isOccupied = tableState
                                                        .occupiedTableNumbers
                                                        .contains(
                                                          selectedTable,
                                                        );
                                                    String name = "";

                                                    if (!isOccupied) {
                                                      final promptName =
                                                          await _showTableNamePrompt(
                                                            context,
                                                          );
                                                      if (promptName == null)
                                                        return;
                                                      name = promptName;
                                                    } else {
                                                      // Inherit existing name for additions
                                                      name =
                                                          tableState
                                                              .occupiedTableNames[selectedTable] ??
                                                          "";
                                                    }

                                                    if (context.mounted) {
                                                      _createOrder(
                                                        context,
                                                        'NONE',
                                                        total,
                                                        status: 'UNPAID',
                                                        taxPercentage: taxRate,
                                                        serviceChargePercentage:
                                                            serviceChargeRate,
                                                        customerName: name,
                                                      );
                                                    }
                                                  },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  AppPallete.secondary,
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              minimumSize:
                                                  const Size.fromHeight(56),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                const Icon(
                                                  Icons
                                                      .table_restaurant_rounded,
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Simpan Meja (Dine-In)',
                                                  style: GoogleFonts.outfit(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),

                                  // 2. Show Payment Buttons ONLY if:
                                  // - It's Takeaway (table 0)
                                  // - OR it's Dine-In and already occupied (paying existing bill)
                                  BlocBuilder<TableBloc, TableState>(
                                    builder: (context, tableState) {
                                      final selectedTable =
                                          tableState.selectedTableNumber;
                                      final isOccupied = tableState
                                          .occupiedTableNumbers
                                          .contains(selectedTable);
                                      final isTakeaway = selectedTable == 0;

                                      // Show Payment Buttons ONLY IF:
                                      // 1. It's Takeaway
                                      // 2. OR it's Dine-In AND we are specifically in Payout Mode
                                      if (isTakeaway ||
                                          (isOccupied && isPayoutMode)) {
                                        return Wrap(
                                          spacing: 12,
                                          runSpacing: 12,
                                          children: [
                                            if (storeSettings.isCashEnabled)
                                              _buildPaymentButton(
                                                context: context,
                                                label: 'TUNAI',
                                                icon: Icons.payments_rounded,
                                                color: AppPallete.primary,
                                                isPrimary: true,
                                                onPressed: isSkipped
                                                    ? null
                                                    : () => _showCashPaymentDialog(
                                                        context,
                                                        total,
                                                        taxPercentage: taxRate,
                                                        serviceChargePercentage:
                                                            serviceChargeRate,
                                                        customerName: tableState
                                                            .occupiedTableNames[selectedTable],
                                                      ),
                                              ),
                                            if (storeSettings.isQrisEnabled)
                                              _buildPaymentButton(
                                                context: context,
                                                label: 'QRIS',
                                                icon: Icons
                                                    .qr_code_scanner_rounded,
                                                color: Colors.blue,
                                                onPressed: isSkipped
                                                    ? null
                                                    : () => _showQRISPaymentDialog(
                                                        context,
                                                        total,
                                                        taxPercentage: taxRate,
                                                        serviceChargePercentage:
                                                            serviceChargeRate,
                                                        customerName: tableState
                                                            .occupiedTableNames[selectedTable],
                                                        serverKey:
                                                            storeSettings
                                                                .isMidtransSandbox
                                                            ? (storeSettings
                                                                      .midtransServerKeySandbox ??
                                                                  '')
                                                            : (storeSettings
                                                                      .midtransServerKey ??
                                                                  ''),
                                                        isProduction:
                                                            !storeSettings
                                                                .isMidtransSandbox,
                                                      ),
                                              ),
                                            if (storeSettings.isTransferEnabled)
                                              _buildPaymentButton(
                                                context: context,
                                                label: 'TRANSFER',
                                                icon: Icons
                                                    .account_balance_rounded,
                                                color: Colors.teal,
                                                onPressed: isSkipped
                                                    ? null
                                                    : () => _showTransferPaymentDialog(
                                                        context,
                                                        total,
                                                        taxPercentage: taxRate,
                                                        serviceChargePercentage:
                                                            serviceChargeRate,
                                                        customerName: tableState
                                                            .occupiedTableNames[selectedTable],
                                                        bankName:
                                                            storeSettings
                                                                .bankName ??
                                                            '-',
                                                        bankNumber:
                                                            storeSettings
                                                                .bankAccountNumber ??
                                                            '-',
                                                      ),
                                              ),
                                            if (storeSettings.isCardEnabled)
                                              _buildPaymentButton(
                                                context: context,
                                                label: 'KARTU',
                                                icon: Icons.credit_card_rounded,
                                                color: Colors.orange,
                                                onPressed: isSkipped
                                                    ? null
                                                    : () => _showCardPaymentDialog(
                                                        context,
                                                        total,
                                                        taxPercentage: taxRate,
                                                        serviceChargePercentage:
                                                            serviceChargeRate,
                                                        customerName: tableState
                                                            .occupiedTableNames[selectedTable],
                                                      ),
                                              ),
                                          ],
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          );
        },
      ),
    );
  }

  // --- Logic Methods ---

  Future<void> _handleOrderCreated(
    BuildContext context,
    OrderEntity order,
  ) async {
    final cartBloc = context.read<CartBloc>();
    final rootNavigator = Navigator.of(context, rootNavigator: true);

    showSnackbar(rootNavigator.context, 'Order created successfully!');

    if (isMobileCheckoutFlow) {
      // DO NOT pop if we are in the middle of a QRIS payment initiation
      if (order.status == 'UNPAID' && order.payment?.method == 'QRIS') {
         debugPrint('--- [FLOWPOS] Keeping checkout screen open for QRIS WebView ---');
      } else {
         Navigator.of(context).pop();
      }
    }

    if (!rootNavigator.mounted) {
      cartBloc.add(const ClearCartEvent());
      return;
    }

    // Block receipt printing for UNPAID QRIS orders
    bool shouldPrint = false;
    if (order.status == 'PAID') {
      shouldPrint = isMobileCheckoutFlow
          ? await _showMobilePrintPrompt(rootNavigator)
          : await _showIpadPrintPrompt(rootNavigator);
    }
    if (order.payment?.method == 'QRIS' && order.status == 'UNPAID') {
      debugPrint('--- [FLOWPOS ALERT] ---');
      debugPrint('Blocking print for UNPAID QRIS initiation.');
      debugPrint('-----------------------');
      return; // Block print for QRIS initiation
    }
    
    debugPrint('--- [FLOWPOS ALERT] ---');
    debugPrint('Proceeding with print. Status: ${order.status}, Method: ${order.payment?.method}');
    debugPrint('-----------------------');

    if (shouldPrint && rootNavigator.mounted) {
      await _printInvoice(rootNavigator, order);
    }

    cartBloc.add(const ClearCartEvent());
  }

  Future<bool> _showMobilePrintPrompt(NavigatorState rootNavigator) async {
    return _showModernPrintSheet(
      rootNavigator,
      title: 'Cetak Struk?',
      message: 'Apakah Anda ingin mencetak struk transaksi ini sekarang?',
    );
  }

  Future<bool> _showIpadPrintPrompt(NavigatorState rootNavigator) async {
    return _showModernPrintSheet(
      rootNavigator,
      title: 'Cetak Struk?',
      message: 'Apakah Anda ingin mencetak struk transaksi ini sekarang?',
    );
  }


  Future<bool> _showModernPrintSheet(
    NavigatorState rootNavigator, {
    required String title,
    required String message,
    bool isTableOrder = false,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: rootNavigator.context,
      showDragHandle: true,
      backgroundColor: AppPallete.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        (isTableOrder
                                ? AppPallete.secondary
                                : AppPallete.primary)
                            .withAlpha(15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isTableOrder
                        ? Icons.receipt_long_rounded
                        : Icons.print_rounded,
                    size: 32,
                    color: isTableOrder
                        ? AppPallete.secondary
                        : AppPallete.primary,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppPallete.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    color: AppPallete.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Nanti Saja',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppPallete.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(sheetContext, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isTableOrder
                              ? AppPallete.secondary
                              : AppPallete.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Ya, Cetak',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  Future<void> _printInvoice(
    NavigatorState rootNavigator,
    OrderEntity order,
  ) async {
    final printerService = serviceLocator<ThermalReceiptPrinterService>();
    final rootContext = rootNavigator.context;
    final storeSettings = _resolveStoreSettings(rootContext);
    final cashierName = _resolveCashierName(rootContext);

    try {
      final connected = await printerService.isConnected;
      if (!rootContext.mounted) return;

      if (!connected) {
        final selectedDevice = await printerService.selectDevice(
          context: rootContext,
        );
        if (selectedDevice == null) return;
        await printerService.connect(macAddress: selectedDevice.macAddress);
        if (!rootContext.mounted) return;
      }

      await printerService.printOrderReceipt(
        context: rootContext,
        order: order,
        storeSettings: storeSettings,
        cashierName: cashierName,
      );
      if (rootContext.mounted)
        showSnackbar(rootContext, 'Receipt printed successfully.');
    } catch (error) {
      if (!rootContext.mounted) return;
      showSnackbar(rootContext, 'Gagal mencetak struk.');
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
    return 'Kasir';
  }

  void _showCashPaymentDialog(
    BuildContext context,
    int total, {
    required double taxPercentage,
    required double serviceChargePercentage,
    String? customerName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CashPaymentDialog(
        total: total,
        onConfirmPayment: (amountPaid) {
          _createOrder(
            context,
            'CASH',
            total,
            amountPaid: amountPaid,
            status: 'PAID', // Cash is always paid instantly
            taxPercentage: taxPercentage,
            serviceChargePercentage: serviceChargePercentage,
            customerName: customerName,
          );
        },
      ),
    );
  }

  void _showQRISPaymentDialog(
    BuildContext context,
    int total, {
    required double taxPercentage,
    required double serviceChargePercentage,
    String? customerName,
    required String serverKey,
    required bool isProduction,
  }) async {
    if (serverKey.isEmpty) {
      showSnackbar(
        context,
        'Konfigurasi QRIS belum lengkap (Server Key kosong untuk mode ${isProduction ? 'Produksi' : 'Sandbox'})',
      );
      return;
    }

    // Completer to get the actual database UUID once the order is created
    final Completer<String> dbOrderIdCompleter = Completer<String>();

    final now = DateTime.now();
    final tempOrderId = 'QRIS-${now.millisecondsSinceEpoch}';
    OrderEntity? createdOrder;

    // Listen to the bloc stream to catch the Created event for our tempOrderId
    final subscription = context.read<OrderBloc>().stream.listen((state) {
      if (state is OrderCreated && state.order.orderNumber == tempOrderId) {
        createdOrder = state.order;
        if (!dbOrderIdCompleter.isCompleted) {
dbOrderIdCompleter.complete(state.order.id);
        }
      }
    });

    // 1. Show a single dialog that handles its own internal state
    final midtransService = MidtransService(
      serverKey: serverKey,
      isProduction: isProduction,
    );

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return _QRISFlowManager(
          midtransService: midtransService,
          orderId: tempOrderId,
          total: total,
          onSnapUrlReady: (url) {
            // Create UNPAID order once URL is ready
            _createOrder(
              context,
              'QRIS',
              total,
              status: 'UNPAID',
              taxPercentage: taxPercentage,
              serviceChargePercentage: serviceChargePercentage,
              customerName: customerName,
              orderNumber: tempOrderId,
              paymentLink: url,
            );
          },
          onSuccess: () async {
            debugPrint('--- [QRIS DEBUG] WebView onSuccess() CALLBACK TRIGGERED ---');
            try {
              final dbId = await dbOrderIdCompleter.future.timeout(const Duration(seconds: 20));
              if (context.mounted) {
                context.read<OrderBloc>().add(
                  SettleOrderEvent(
                    orderId: dbId,
                    method: 'QRIS',
                    amountPaid: total,
                    amountDue: total,
                    changeGiven: 0,
                  ),
                );
                if (createdOrder != null) {
                  final updatedOrder = createdOrder!.copyWith(status: 'PAID');
                  if (context.mounted) {
                    await _printInvoice(Navigator.of(context, rootNavigator: true), updatedOrder);
                  }
                }
              }
            } catch (e) {
              debugPrint('--- [QRIS DEBUG] Settlement error: $e ---');
            } finally {
              subscription.cancel();
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            }
          },
          onFailure: (reason) {
            debugPrint('--- [QRIS DEBUG] Payment FAILED: $reason ---');
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pembayaran QRIS Gagal atau Dibatalkan'),
                  backgroundColor: AppPallete.error,
                ),
              );
            }
            subscription.cancel();
            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
          },
          onCancel: () {
            debugPrint('--- [QRIS DEBUG] Payment CANCELLED by user ---');
            subscription.cancel();
            if (dialogCtx.mounted) Navigator.pop(dialogCtx);
          },
        );
      },
    );
  }

  void _showTransferPaymentDialog(
    BuildContext context,
    int total, {
    required double taxPercentage,
    required double serviceChargePercentage,
    String? customerName,
    required String bankName,
    required String bankNumber,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransferBankDialog(
        total: total,
        bankName: bankName,
        accountNumber: bankNumber,
        onConfirm: () {
          _createOrder(
            context,
            'TRANSFER',
            total,
            taxPercentage: taxPercentage,
            serviceChargePercentage: serviceChargePercentage,
            customerName: customerName,
          );
        },
      ),
    );
  }

  void _showCardPaymentDialog(
    BuildContext context,
    int total, {
    required double taxPercentage,
    required double serviceChargePercentage,
    String? customerName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CardPaymentDialog(
        total: total,
        onConfirm: () {
          _createOrder(
            context,
            'CARD',
            total,
            status: 'PAID', // Card is verified via EDC before checkout
            taxPercentage: taxPercentage,
            serviceChargePercentage: serviceChargePercentage,
            customerName: customerName,
          );
        },
      ),
    );
  }

  Widget _buildPaymentButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    final width = MediaQuery.of(context).size.width;
    final isIpad = width > 600;

    return SizedBox(
      width: isIpad ? (width * 0.45 - 60) / 2 : (width - 60) / 2,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? color : color.withAlpha(20),
          foregroundColor: isPrimary ? Colors.white : color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void _createOrder(
    BuildContext context,
    String method,
    int total, {
    int? amountPaid,
    String status = 'UNPAID', // Safer default
    required double taxPercentage,
    required double serviceChargePercentage,
    String? customerName,
    String? orderNumber,
    String? paymentLink,
  }) {
    final cartBloc = context.read<CartBloc>();
    final orderBloc = context.read<OrderBloc>();
    final userBloc = context.read<UserBloc>();

    final cartState = cartBloc.state;
    if (cartState is! CartLoaded) return;

    final userState = userBloc.state;
    if (userState is! UserLoggedIn) {
      showSnackbar(context, 'Sesi berakhir, silakan login kembali');
      return;
    }

    final now = DateTime.now();
    final orderNumberToUse = orderNumber ??
        'ORD-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

    final orderItems = cartState.items.map((cartItem) {
      final modifierSnapshot = cartItem.selectedModifiers.values
          .whereType<SelectedModifier>()
          .map((modifier) => '${modifier.optionName}: ${modifier.name}')
          .join(', ');

      return OrderItem(
        menuItemId: cartItem.menuItemId,
        menuName: cartItem.name,
        quantity: cartItem.quantity,
        unitPrice: (cartItem.basePrice + _modifiersUnitPrice(cartItem)).toInt(),
        notes: cartItem.notes,
        modifierSnapshot: modifierSnapshot.isNotEmpty ? modifierSnapshot : null,
      );
    }).toList();

    final shiftId =
        serviceLocator<CashierShiftLocalService>().getActiveShift(
              userState.user.id,
            )?['shiftId']
            as String?;

    orderBloc.add(
      CreateOrderEvent(
        orderNumber: orderNumberToUse,
        tableNumber: context.read<TableBloc>().state.selectedTableNumber,
        cashierId: userState.user.id,
        subtotal: cartState.totalAmount,
        tax: (cartState.totalAmount * taxPercentage / 100),
        serviceCharge: (cartState.totalAmount * serviceChargePercentage / 100),
        total: total,
        method: method,
        amountPaid: amountPaid ?? (status == 'PAID' ? total : 0),
        items: orderItems,
        shiftId: shiftId,
        status: status,
        customerName: customerName,
        paymentLink: paymentLink,
      ),
    );
  }

  Future<String?> _showTableNamePrompt(BuildContext context) async {
    final controller = TextEditingController();
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppPallete.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 32,
            left: 28,
            right: 28,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppPallete.secondary.withAlpha(15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.drive_file_rename_outline_rounded,
                      color: AppPallete.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Nama Pesanan / Meja',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppPallete.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Opsional: Berikan nama atau pengenal untuk pesanan di meja ini agar lebih mudah ditemukan.',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AppPallete.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                autofocus: true,
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Contoh: Kak Kevin / Meja Jendela',
                  hintStyle: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: AppPallete.textSecondary.withAlpha(127),
                  ),
                  filled: true,
                  fillColor: AppPallete.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(sheetContext, ""),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Tanpa Nama',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppPallete.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext, controller.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppPallete.secondary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Simpan Pesanan',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  int _calculateCharge(int subtotal, double percentage) =>
      (subtotal * percentage / 100).round();

  String _formatPercentage(double percentage) {
    if (percentage == percentage.truncateToDouble())
      return percentage.toStringAsFixed(0);
    return percentage
        .toStringAsFixed(2)
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }

  int _modifiersUnitPrice(Cart item) {
    if (item.quantity <= 0) return 0;
    final perUnitPrice = item.totalPrice ~/ item.quantity;
    final modifiersUnitPrice = perUnitPrice - item.basePrice;
    return modifiersUnitPrice < 0 ? 0 : modifiersUnitPrice;
  }
}

/// New Internal Helper Widget to manage the QRIS Flow UI without pop/push races
class _QRISFlowManager extends StatefulWidget {
  final MidtransService midtransService;
  final String orderId;
  final int total;
  final Function(String) onSnapUrlReady;
  final VoidCallback onSuccess;
  final Function(String) onFailure;
  final VoidCallback onCancel;

  const _QRISFlowManager({
    required this.midtransService,
    required this.orderId,
    required this.total,
    required this.onSnapUrlReady,
    required this.onSuccess,
    required this.onFailure,
    required this.onCancel,
  });

  @override
  State<_QRISFlowManager> createState() => _QRISFlowManagerState();
}

class _QRISFlowManagerState extends State<_QRISFlowManager> {
  String? _snapUrl;
  String? _error;
  bool _isLoading = true;

  @override
  void dispose() {
    debugPrint('--- [QRIS DEBUG] _QRISFlowManager DISPOSED ---');
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSnapUrl();
  }

  Future<void> _loadSnapUrl() async {
    try {
      final result = await widget.midtransService.generateSnapUrl(
        orderId: widget.orderId,
        amount: widget.total,
      );

      if (mounted) {
        if (result['success']) {
          final url = result['redirect_url'];
          widget.onSnapUrlReady(url);
          setState(() {
            _snapUrl = url;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = result['message'];
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return AlertDialog(
        title: const Text('Gagal membuat pembayaran'),
        content: Text(_error!),
        actions: [
          TextButton(onPressed: widget.onCancel, child: const Text('Tutup')),
        ],
      );
    }

    return MidtransWebView(
      url: _snapUrl!,
      orderId: widget.orderId,
      serverKey: widget.midtransService.serverKey,
      isProduction: widget.midtransService.isProduction,
      onUrlChange: (url) {
        debugPrint('--- [QRIS DEBUG] WebView Loading URL: $url ---');
      },
      onSuccess: widget.onSuccess,
      onFailure: widget.onFailure,
      onCancel: widget.onCancel,
    );
  }
}

// --- Helper Widgets ---

class _OrderItemTile extends StatelessWidget {
  final Cart cartItem;
  final Function(int) onQuantityChanged;
  final VoidCallback onRemove;

  const _OrderItemTile({
    required this.cartItem,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final initials = cartItem.name.length >= 2
        ? cartItem.name.substring(0, 2).toUpperCase()
        : cartItem.name.toUpperCase();
    final selectedModifierStrings = cartItem.modifierSnapshot != null
        ? [cartItem.modifierSnapshot!]
        : cartItem.selectedModifiers.values
              .whereType<SelectedModifier>()
              .map((m) => '${m.optionName}: ${m.name}')
              .toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPallete.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppPallete.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              initials,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppPallete.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cartItem.name,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (selectedModifierStrings.isNotEmpty)
                  Text(
                    selectedModifierStrings.join(', '),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: AppPallete.textSecondary,
                    ),
                  ),
                if (cartItem.notes != null && cartItem.notes!.isNotEmpty)
                  Text(
                    cartItem.notes!,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: AppPallete.warning,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  formatRupiah(cartItem.totalPrice),
                  style: GoogleFonts.outfit(
                    color: AppPallete.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _buildSmallQtyBtn(
                Icons.remove,
                () => onQuantityChanged(cartItem.quantity - 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '${cartItem.quantity}',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                ),
              ),
              _buildSmallQtyBtn(
                Icons.add,
                () => onQuantityChanged(cartItem.quantity + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallQtyBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: AppPallete.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 14, color: AppPallete.primary),
      ),
    );
  }
}
