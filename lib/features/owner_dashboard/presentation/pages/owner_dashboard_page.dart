import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_dashboard_ipad_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_dashboard_mobile_page.dart';
import 'package:flutter/material.dart';

class OwnerDashboardPage extends StatelessWidget {
  const OwnerDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return const OwnerDashboardMobilePage();
    } else {
      return OwnerDashboardIpadPage();
    }
  }
}
