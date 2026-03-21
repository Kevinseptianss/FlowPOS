import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/theme/app_theme.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flow_pos/features/auth/presentation/pages/sign_in_page.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/cashier_page.dart';
import 'package:flow_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_dashboard_page.dart';
import 'package:flow_pos/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDependencies();
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => serviceLocator<UserBloc>()),
        BlocProvider(create: (_) => serviceLocator<AuthBloc>()),
        BlocProvider(create: (_) => serviceLocator<CategoryBloc>()),
      ],
      child: const MyApp(),
    ),
  );
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
      home: BlocBuilder<UserBloc, UserState>(
        builder: (context, state) {
          if (state is UserLoggedIn) {
            if (state.user.role == 'cashier') {
              return const CashierPage();
            } else if (state.user.role == 'owner') {
              return const OwnerDashboardPage();
            }

            return const Scaffold(body: Center(child: Text('Unknown role')));
          }

          return const SignInPage();
        },
      ),
    );
  }
}
