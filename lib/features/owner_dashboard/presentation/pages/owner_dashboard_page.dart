import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_dashboard_ipad_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_dashboard_mobile_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_products_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_settings_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_stock_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_store_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/owner_bottom_nav_bar.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/owner_sidebar.dart';
import 'package:flutter/material.dart';

class OwnerDashboardPage extends StatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  State<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends State<OwnerDashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _ResponsiveDashboardView(),
    const OwnerProductsPage(),
    const OwnerStockPage(),
    const OwnerStorePage(),
    const OwnerSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppPallete.background,
        body: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Sub-page view
              _pages[_currentIndex],
              
              // Floating Navigation Bar
              Positioned(
                left: 20,
                right: 20,
                bottom: 20,
                child: OwnerBottomNavBar(
                  currentIndex: _currentIndex,
                  onIndexChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          OwnerSidebar(
            currentIndex: _currentIndex,
            onIndexChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
          Expanded(child: _pages[_currentIndex]),
        ],
      ),
    );
  }
}

class _ResponsiveDashboardView extends StatelessWidget {
  const _ResponsiveDashboardView();

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return const OwnerDashboardMobilePage();
    } else {
      return const OwnerDashboardIpadPage();
    }
  }
}
