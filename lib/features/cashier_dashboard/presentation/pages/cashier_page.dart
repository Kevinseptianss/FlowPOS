import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_ipad_page.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_history_page.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_mobile_page.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_shift_page.dart';
import 'package:flow_pos/features/store_settings/presentation/bloc/store_settings_bloc.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  late final StoreSettingsBloc _storeSettingsBloc;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _storeSettingsBloc = context.read<StoreSettingsBloc>();
    _storeSettingsBloc.add(GetStoreSettingsEvent());
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tabs = <Widget>[
      screenWidth < 600 ? const CashierMobilePage() : const CashierIpadPage(),
      const CashierHistoryPage(),
      const CashierShiftPage(),
    ];

    if (screenWidth < 600) {
      return Scaffold(
        body: IndexedStack(index: _selectedTabIndex, children: tabs),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedTabIndex,
          selectedItemColor: AppPallete.primary,
          onTap: (index) {
            setState(() {
              _selectedTabIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale_outlined),
              activeIcon: Icon(Icons.point_of_sale),
              label: 'Transaction',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.badge_outlined),
              activeIcon: Icon(Icons.badge),
              label: 'Shift',
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedTabIndex,
              selectedIconTheme: const IconThemeData(color: AppPallete.primary),
              selectedLabelTextStyle: const TextStyle(
                color: AppPallete.primary,
              ),
              onDestinationSelected: (index) {
                setState(() {
                  _selectedTabIndex = index;
                });
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.point_of_sale_outlined),
                  selectedIcon: Icon(Icons.point_of_sale),
                  label: Text('Transaction'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.history_outlined),
                  selectedIcon: Icon(Icons.history),
                  label: Text('History'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.badge_outlined),
                  selectedIcon: Icon(Icons.badge),
                  label: Text('Shift'),
                ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(index: _selectedTabIndex, children: tabs),
            ),
          ],
        ),
      );
    }
  }
}
