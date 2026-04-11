import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_order_detail_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/analytic_section.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/manage_menu_section.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/order_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OwnerDashboardIpadPage extends StatefulWidget {
  const OwnerDashboardIpadPage({super.key});

  @override
  State<OwnerDashboardIpadPage> createState() => _OwnerDashboardIpadPageState();
}

class _OwnerDashboardIpadPageState extends State<OwnerDashboardIpadPage> {
  List<OrderEntity> _orders = [];

  @override
  void initState() {
    super.initState();
    context.read<OrderBloc>().add(GetAllOrdersEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderBloc, OrderState>(
      listener: (context, state) {
        if (state is OrdersLoaded) {
          setState(() {
            _orders = state.orders;
          });
        }
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AnalyticSection(),
                  const SizedBox(height: 40),
                  SizedBox(
                    height: 600, // Fixed height for order list area
                    child: OrderSection(
                      orders: _orders,
                      onOrderTap: (order) {
                        Navigator.push(
                          context,
                          OwnerOrderDetailPage.route(order),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(color: AppPallete.divider.withAlpha(100)),
              ),
            ),
            child: const ManageMenuSection(),
          ),
        ],
      ),
    );
  }
}
