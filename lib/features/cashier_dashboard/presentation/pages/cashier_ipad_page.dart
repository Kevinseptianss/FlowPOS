import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/list_menu_section.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/list_order_section.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/table_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashierIpadPage extends StatelessWidget {
  const CashierIpadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          showSnackbar(context, state.message);
        }
      },
      child: Scaffold(
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
              BlocBuilder<UserBloc, UserState>(
                builder: (context, state) {
                  if (state is UserLoggedIn) {
                    return Text(
                      'Cashier: ${state.user.name}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppPallete.onPrimary,
                      ),
                    );
                  }

                  return const SizedBox();
                },
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {
                context.read<AuthBloc>().add(SignOutEvent());
              },
              icon: const Icon(Icons.logout),
              color: AppPallete.onPrimary,
              tooltip: 'Logout',
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Row(
          children: [
            Expanded(flex: 1, child: TableSection()),
            Expanded(flex: 2, child: ListMenuSection()),
            Expanded(flex: 1, child: ListOrderSection()),
          ],
        ),
      ),
    );
  }
}
