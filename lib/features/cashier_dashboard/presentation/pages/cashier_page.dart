import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_ipad_page.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_mobile_page.dart';
import 'package:flow_pos/features/store_settings/presentation/bloc/store_settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashierPage extends StatefulWidget {
  const CashierPage({super.key});

  @override
  State<CashierPage> createState() => _CashierPageState();
}

class _CashierPageState extends State<CashierPage> {
  late final StoreSettingsBloc _storeSettingsBloc;

  @override
  void initState() {
    super.initState();
    _storeSettingsBloc = context.read<StoreSettingsBloc>();
    _storeSettingsBloc.add(StartStoreSettingsRealtimeEvent());
  }

  @override
  void dispose() {
    _storeSettingsBloc.add(StopStoreSettingsRealtimeEvent());
    super.dispose();
  }

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
