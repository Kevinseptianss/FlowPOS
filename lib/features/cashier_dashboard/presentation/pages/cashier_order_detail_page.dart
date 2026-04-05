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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashierOrderDetailPage extends StatelessWidget {
  final OrderEntity order;

  const CashierOrderDetailPage({super.key, required this.order});

  static MaterialPageRoute route(OrderEntity order) => MaterialPageRoute(
    builder: (context) => CashierOrderDetailPage(order: order),
  );

  Future<void> _onPrintPressed(BuildContext context) async {
    final printerService = serviceLocator<ThermalReceiptPrinterService>();
    final storeSettings = _resolveStoreSettings(context);
    final cashierName = _resolveCashierName(context);

    try {
      final connected = await printerService.isConnected;
      if (!connected) {
        final devices = await printerService.getPairedDevices();

        if (devices.isEmpty) {
          throw Exception(
            'No paired printer found. Please pair your printer first.',
          );
        }

        if (!context.mounted) {
          return;
        }

        final selectedDevice = await _pickPrinterDevice(context, devices);
        if (selectedDevice == null) {
          return;
        }

        await printerService.connect(macAddress: selectedDevice.macAddress);
      }

      await printerService.printOrderReceipt(
        order: order,
        storeSettings: storeSettings,
        cashierName: cashierName,
      );

      if (!context.mounted) {
        return;
      }

      showSnackbar(context, 'Receipt printed successfully.');
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      final message = error is Exception
          ? error.toString().replaceFirst('Exception: ', '')
          : 'Failed to print receipt.';
      showSnackbar(context, message);
    }
  }

  StoreSettings _resolveStoreSettings(BuildContext context) {
    final state = context.read<StoreSettingsBloc>().state;

    if (state is StoreSettingsLoaded) {
      return state.storeSettings;
    }

    if (state is StoreSettingsUpdated) {
      return state.storeSettings;
    }

    return const StoreSettings.zero();
  }

  String _resolveCashierName(BuildContext context) {
    final userState = context.read<UserBloc>().state;

    if (userState is UserLoggedIn) {
      return userState.user.name;
    }

    return 'Cashier';
  }

  Future<PrinterDevice?> _pickPrinterDevice(
    BuildContext context,
    List<PrinterDevice> devices,
  ) {
    return showModalBottomSheet<PrinterDevice>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppPallete.surface,
      builder: (modalContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Select Printer',
                  style: Theme.of(modalContext).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppPallete.textPrimary,
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: devices.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (_, index) {
                    final device = devices[index];

                    return ListTile(
                      leading: const Icon(Icons.print_rounded),
                      title: Text(
                        device.name.isEmpty ? 'Unknown Printer' : device.name,
                      ),
                      subtitle: Text(device.macAddress),
                      onTap: () => Navigator.pop(modalContext, device),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: const Text('Transaction Detail'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              children: [
                _HeadlineOrderCard(order: order),
                const SizedBox(height: 14),
                _SectionShell(
                  title: 'Payment',
                  child: Column(
                    children: [
                      _DetailRow(label: 'Method', value: order.payment.method),
                      _DetailRow(
                        label: 'Amount Due',
                        value: formatRupiah(order.payment.amountDue),
                      ),
                      _DetailRow(
                        label: 'Amount Paid',
                        value: formatRupiah(order.payment.amountPaid),
                      ),
                      _DetailRow(
                        label: 'Change',
                        value: formatRupiah(order.payment.changeGiven),
                        highlighted: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionShell(
                  title: 'Items (${order.items.length})',
                  child: order.items.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No items found on this order.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppPallete.textPrimary),
                          ),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < order.items.length; i++)
                              _ItemTile(index: i + 1, item: order.items[i]),
                          ],
                        ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: AppPallete.surface,
                border: Border(top: BorderSide(color: AppPallete.divider)),
              ),
              child: FilledButton.icon(
                onPressed: () => _onPrintPressed(context),
                icon: const Icon(Icons.print_rounded),
                label: const Text('Print'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: AppPallete.primary,
                  foregroundColor: AppPallete.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeadlineOrderCard extends StatelessWidget {
  final OrderEntity order;

  const _HeadlineOrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppPallete.primary, AppPallete.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.orderNumber,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppPallete.onPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            DatetimeFormatter.formatDateTime(order.createdAt),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppPallete.onPrimary.withAlpha(225),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WhitePill(label: 'Table T${order.tableNumber}'),
              _WhitePill(label: '${order.items.length} items'),
              _WhitePill(label: order.payment.method),
              _WhitePill(label: formatRupiah(order.total), isStrong: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _WhitePill extends StatelessWidget {
  final String label;
  final bool isStrong;

  const _WhitePill({required this.label, this.isStrong = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(30),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppPallete.onPrimary,
          fontWeight: isStrong ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPallete.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppPallete.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlighted;

  const _DetailRow({
    required this.label,
    required this.value,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppPallete.textPrimary),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: highlighted ? AppPallete.primary : AppPallete.textPrimary,
              fontWeight: highlighted ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final int index;
  final OrderItem item;

  const _ItemTile({required this.index, required this.item});

  @override
  Widget build(BuildContext context) {
    final subtotal = item.quantity * item.unitPrice;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppPallete.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$index. ${item.menuName}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppPallete.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.quantity} x ${formatRupiah(item.unitPrice)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPallete.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (item.notes != null && item.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Notes: ${item.notes}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPallete.textPrimary),
            ),
          ],
          if (item.modifierSnapshot != null &&
              item.modifierSnapshot!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Modifier: ${item.modifierSnapshot}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPallete.textPrimary),
            ),
          ],
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              formatRupiah(subtotal),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppPallete.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
