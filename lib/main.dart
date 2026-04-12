import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/theme/app_theme.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flow_pos/features/auth/presentation/pages/sign_in_page.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_page.dart';
import 'package:flow_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flow_pos/features/menu_item/presentation/bloc/menu_item_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/cart_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/table_bloc.dart';
import 'package:flow_pos/features/modifier_option/presentation/bloc/modifier_option_bloc.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_dashboard_page.dart';
import 'package:flow_pos/features/store_settings/presentation/bloc/store_settings_bloc.dart';
import 'package:flow_pos/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initDependencies();
    runApp(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => serviceLocator<UserBloc>()),
          BlocProvider(create: (_) => serviceLocator<AuthBloc>()),
          BlocProvider(create: (_) => serviceLocator<CategoryBloc>()),
          BlocProvider(create: (_) => serviceLocator<MenuItemBloc>()),
          BlocProvider(create: (_) => serviceLocator<ModifierOptionBloc>()),
          BlocProvider(create: (_) => serviceLocator<CartBloc>()),
          BlocProvider(create: (_) => serviceLocator<TableBloc>()),
          BlocProvider(create: (_) => serviceLocator<OrderBloc>()),
          BlocProvider(create: (_) => serviceLocator<StoreSettingsBloc>()),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'Failed to initialize app:\n$e',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(IsLoggedInEvent());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlowPOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightThemeMode,
      themeMode: ThemeMode.light,
      home: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoggedIn) {
            if (state.user.role == 'cashier') {
              return const CashierPage();
            } else if (state.user.role == 'owner' || state.user.role == 'admin') {
              return const OwnerDashboardPage();
            }
          }

          // While we wait for Auth to confirm if the user is already logged in, show a loading screen
          return Scaffold(
            backgroundColor: AppPallete.background,
            body: BlocBuilder<AuthBloc, AuthState>(
              builder: (context, authState) {
                if (authState is AuthLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const SignInPage();
              },
            ),
          );
        },
      ),
    );
  }
}
