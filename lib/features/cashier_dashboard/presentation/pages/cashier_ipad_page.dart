import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/services/cashier_shift_local_service.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_logout_dialog.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/cart_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/list_menu_section.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/list_order_section.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/table_section.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/table_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/domain/entities/cart.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:flow_pos/features/shift/presentation/bloc/shift_bloc.dart';
import 'package:flow_pos/features/shift/presentation/pages/open_shift_page.dart';
import 'package:flow_pos/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

class CashierIpadPage extends StatefulWidget {
  const CashierIpadPage({super.key});

  @override
  State<CashierIpadPage> createState() => _CashierIpadPageState();
}

class _CashierIpadPageState extends State<CashierIpadPage> {
  late final CashierShiftLocalService _cashierShiftLocalService;

  String? _cashierId;
  bool _isWarningBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _cashierShiftLocalService = serviceLocator<CashierShiftLocalService>();

    final userState = context.read<UserBloc>().state;
    if (userState is UserLoggedIn) {
      _cashierId = userState.user.id;
      // Fetch active shift from database on init
      context.read<ShiftBloc>().add(GetActiveShiftEvent(cashierId: _cashierId!));
      // Fetch initial orders to populate occupied tables
      context.read<OrderBloc>().add(GetAllOrdersEvent());
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showLogoutDialog(
      context,
      accountLabel: 'cashier account',
    );

    if (!mounted || !shouldLogout) {
      return;
    }

    context.read<AuthBloc>().add(SignOutEvent());
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserBloc>().state;
    final userId = userState is UserLoggedIn ? userState.user.id : '';
    final isSkipped = _cashierShiftLocalService.isShiftSkipped(userId);

    final shiftState = context.watch<ShiftBloc>().state;
    final hasActiveShift = shiftState is ShiftOpened;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Row(
          children: [
            Text(
              'FlowPOS',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: AppPallete.onPrimary),
            ),
            const SizedBox(width: 16),
            if (userState is UserLoggedIn)
              Text(
                'Cashier: ${userState.user.name}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppPallete.onPrimary,
                    ),
              ),
          ],
        ),
        actions: [
          if (hasActiveShift)
            BlocBuilder<TableBloc, TableState>(
              builder: (context, tableState) {
                final tableNum = tableState.selectedTableNumber;
                final isTakeaway = tableNum == 0;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () {
                      // On iPad, table section is already visible
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppPallete.secondary.withAlpha(40),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppPallete.secondary.withAlpha(80),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isTakeaway
                                ? Icons.local_mall_rounded
                                : Icons.table_restaurant_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isTakeaway ? 'Takeaway' : 'Meja T$tableNum',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          else
            IconButton(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              color: AppPallete.onPrimary,
              tooltip: 'Logout',
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthFailure) {
                showSnackbar(context, state.message);
              }
            },
          ),
          BlocListener<ShiftBloc, ShiftState>(
            listener: (context, state) {
              if (state is ShiftNone) {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const OpenShiftPage()),
                );
              } else if (state is ShiftClosed) {
                showSnackbar(
                  context,
                  'Shift ditutup. Data berhasil disimpan ke database.',
                );
                // Refresh
                context.read<ShiftBloc>().add(
                  GetActiveShiftEvent(cashierId: _cashierId!),
                );
              } else if (state is ShiftFailure) {
                showSnackbar(context, 'Gagal: ${state.message}');
              }
            },
          ),
          BlocListener<OrderBloc, OrderState>(
            listener: (context, state) {
              if (state is OrdersLoaded) {
                final occupied = state.orders
                    .where((o) => o.status == 'UNPAID')
                    .map((o) => o.tableNumber)
                    .toSet();

                final names = <int, String>{};
                for (final o in state.orders.where(
                  (o) => o.status == 'UNPAID',
                )) {
                  names[o.tableNumber] = o.customerName ?? 'Guest';
                }

                context.read<TableBloc>().add(
                  UpdateOccupiedTablesEvent(
                    occupied,
                    occupiedTableNames: names,
                  ),
                );

                // Sync cart for current table if it just became occupied or updated
                final tableState = context.read<TableBloc>().state;
                final currentTable = tableState.selectedTableNumber;
                if (currentTable > 0) {
                  final order = state.orders
                      .where(
                        (o) =>
                            o.tableNumber == currentTable &&
                            o.status == 'UNPAID',
                      )
                      .firstOrNull;
                  if (order != null) {
                    final cartItems = order.items
                        .where((i) => !i.isDeleted)
                        .map(
                          (item) => Cart(
                            id: const Uuid().v4(),
                            menuItemId: item.menuItemId,
                            name: item.menuName,
                            basePrice: item.unitPrice,
                            quantity: item.quantity,
                            selectedModifiers: const {},
                            totalPrice: item.unitPrice * item.quantity,
                            variantId: item.variantId,
                            notes: item.notes,
                          ),
                        )
                        .toList();
                    context.read<CartBloc>().add(
                      ReplaceCartItemsEvent(cartItems),
                    );
                  }
                }
              } else if (state is OrderCreated) {
                // Refresh orders list when a new order is created to update occupancy
                context.read<OrderBloc>().add(GetAllOrdersEvent());
              } else if (state is OrderFailure) {
                showSnackbar(context, state.message);
              }
            },
          ),
          BlocListener<TableBloc, TableState>(
            listenWhen: (previous, current) =>
                previous.selectedTableNumber != current.selectedTableNumber,
            listener: (context, tableState) {
              final orderState = context.read<OrderBloc>().state;
              if (orderState is OrdersLoaded) {
                final selectedTable = tableState.selectedTableNumber;
                final order = orderState.orders
                    .where(
                      (o) =>
                          o.tableNumber == selectedTable &&
                          o.status == 'UNPAID',
                    )
                    .firstOrNull;
                if (order != null) {
                  final cartItems = order.items
                      .where((i) => !i.isDeleted)
                      .map(
                        (item) => Cart(
                          id: const Uuid().v4(),
                          menuItemId: item.menuItemId,
                          name: item.menuName,
                          basePrice: item.unitPrice,
                          quantity: item.quantity,
                          selectedModifiers: const {},
                          totalPrice: item.unitPrice * item.quantity,
                          variantId: item.variantId,
                          notes: item.notes,
                        ),
                      )
                      .toList();
                  context.read<CartBloc>().add(ReplaceCartItemsEvent(cartItems));
                } else if (tableState.selectedTableNumber > 0) {
                  context.read<CartBloc>().add(const ClearCartEvent());
                }
              }
            },
          ),
        ],
        child: Column(
          children: [
            if (isSkipped && !_isWarningBannerDismissed)
              Dismissible(
                key: const Key('ipad_shift_warning_banner'),
                onDismissed: (_) {
                  setState(() {
                    _isWarningBannerDismissed = true;
                  });
                },
                child: Container(
                  width: double.infinity,
                  color: AppPallete.warning.withAlpha(50),
                  padding: const EdgeInsets.symmetric(
                    vertical: 8,
                    horizontal: 16,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppPallete.warning,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Shift belum dibuka. Tombol pembayaran akan dinonaktifkan sampai shift dibuka.',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.brown,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _cashierShiftLocalService.clearShiftSkipped(userId);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const OpenShiftPage(),
                            ),
                          );
                        },
                        child: const Text('Buka Shift Sekarang'),
                      ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Row(
                children: [
                  Expanded(flex: 1, child: TableSection()),
                  Expanded(flex: 2, child: ListMenuSection()),
                  Expanded(flex: 1, child: ListOrderSection()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
