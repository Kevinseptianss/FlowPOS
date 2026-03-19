import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_ipad_page.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_mobile_page.dart';
import 'package:flutter/material.dart';

class CashierPage extends StatelessWidget {
  const CashierPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 600) {
      return const CashierMobilePage();
    } else {
      return CashierIpadPage();
    }
  }
}
