import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/services/cashier_shift_local_service.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_ipad_page.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_history_page.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_mobile_page.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_settings_page.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_shift_page.dart';
import 'package:flow_pos/features/shift/presentation/pages/open_shift_page.dart';
import 'package:flow_pos/features/store_settings/presentation/bloc/store_settings_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/table_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/cart_bloc.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  late final StoreSettingsBloc _storeSettingsBloc;
  late final CashierShiftLocalService _shiftLocalService;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _storeSettingsBloc = context.read<StoreSettingsBloc>();
    _storeSettingsBloc.add(GetStoreSettingsEvent());
    _shiftLocalService = serviceLocator<CashierShiftLocalService>();
    
    // Initial data fetch
    final userState = context.read<UserBloc>().state;
    if (userState is UserLoggedIn) {
      context.read<OrderBloc>().add(GetAllOrdersEvent());
    }

    // Ensure cart is empty on start
    context.read<CartBloc>().add(const ClearCartEvent());
  }

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserBloc>().state;
    if (userState is! UserLoggedIn) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userId = userState.user.id;

    return ValueListenableBuilder(
      valueListenable: _shiftLocalService.listenable(),
      builder: (context, box, child) {
        final hasActiveShift = _shiftLocalService.hasActiveShift(userId);
        final isSkipped = _shiftLocalService.isShiftSkipped(userId);

        if (!hasActiveShift && !isSkipped) {
          return const OpenShiftPage();
        }

        return _buildMainDashboard(context);
      },
    );
  }

  Widget _buildMainDashboard(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final tabs = <Widget>[
      isMobile ? const CashierMobilePage() : const CashierIpadPage(),
      const CashierHistoryPage(),
      const CashierShiftPage(),
      const CashierSettingsPage(),
    ];

    Widget mainContent;
    if (isMobile) {
      mainContent = Scaffold(
        backgroundColor: AppPallete.background,
        body: Stack(
          children: [
            IndexedStack(index: _selectedTabIndex, children: tabs),
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _buildCustomBottomNav(),
            ),
          ],
        ),
      );
    } else {
      mainContent = Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedTabIndex,
              backgroundColor: AppPallete.surface,
              indicatorColor: AppPallete.primary.withAlpha(30),
              selectedIconTheme: const IconThemeData(color: AppPallete.primary, size: 28),
              unselectedIconTheme: const IconThemeData(color: AppPallete.textSecondary),
              onDestinationSelected: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.restaurant_menu_rounded),
                  label: Text('Menu'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history_rounded),
                  label: Text('Riwayat'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.person_pin_rounded),
                  label: Text('Shift'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.settings_outlined),
                  label: Text('Pengaturan'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1, color: AppPallete.divider),
            Expanded(child: tabs[_selectedTabIndex]),
          ],
        ),
      );
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<OrderBloc, OrderState>(
          listener: (context, state) {
            if (state is OrdersLoaded) {
              final occupied = state.orders
                  .where((o) => o.status.trim().toUpperCase() == 'UNPAID')
                  .map((o) => o.tableNumber)
                  .toSet();

              final names = <int, String>{};
              for (final o in state.orders.where((o) => o.status.trim().toUpperCase() == 'UNPAID')) {
                final currentStoredName = names[o.tableNumber];
                final candidateName = o.customerName?.trim();
                
                // Logic: 
                // 1. If we don't have a name yet, take it (or Guest if empty)
                // 2. If we have 'Guest' but find a real name now, upgrade to the real name
                // 3. If we already have a real name, don't let it be downgraded to 'Guest'
                if (currentStoredName == null || currentStoredName == 'Guest') {
                  if (candidateName != null && candidateName.isNotEmpty) {
                    names[o.tableNumber] = candidateName;
                  } else if (currentStoredName == null) {
                    names[o.tableNumber] = 'Guest';
                  }
                }
              }

              context.read<TableBloc>().add(
                UpdateOccupiedTablesEvent(
                  occupied,
                  occupiedTableNames: names,
                ),
              );
            } else if (state is OrderCreated) {
              context.read<OrderBloc>().add(GetAllOrdersEvent());
              context.read<CartBloc>().add(ClearCartEvent());
            } else if (state is OrderFailure) {
              showSnackbar(context, state.message);
            }
          },
        ),
      ],
      child: mainContent,
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.restaurant_menu_rounded, 'Menu'),
          _buildNavItem(1, Icons.history_rounded, 'Riwayat'),
          _buildNavItem(2, Icons.person_pin_rounded, 'Shift'),
          _buildNavItem(3, Icons.settings_rounded, 'Pengaturan'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _selectedTabIndex = index),
      customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppPallete.primary.withAlpha(20) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppPallete.primary : AppPallete.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppPallete.primary : AppPallete.textSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
