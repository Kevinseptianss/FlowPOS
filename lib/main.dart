import 'package:flow_pos/core/theme/app_theme.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowPOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightThemeMode,
      home: const CashierPage(),
    );
  }
}
