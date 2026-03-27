import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/domain/entities/selected_modifier.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/table_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/select_table_mobile_page.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/list_order_section.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/menu_item_card.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/modifier_dialog.dart';
import 'package:flow_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/cart_bloc.dart';
import 'package:flow_pos/features/menu_item/presentation/bloc/menu_item_bloc.dart';
import 'package:flow_pos/features/modifier_option/presentation/bloc/modifier_option_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashierMobilePage extends StatefulWidget {
  const CashierMobilePage({super.key});

  @override
  State<CashierMobilePage> createState() => _CashierMobilePageState();
}

class _CashierMobilePageState extends State<CashierMobilePage> {
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    context.read<CategoryBloc>().add(StartCategoriesRealtimeEvent());
    context.read<MenuItemBloc>().add(StartEnabledMenuItemsRealtimeEvent());
  }

  @override
  void dispose() {
    context.read<CategoryBloc>().add(StopCategoriesRealtimeEvent());
    context.read<MenuItemBloc>().add(StopMenuItemsRealtimeEvent());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthFailure) {
          showSnackbar(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: AppPallete.background,
        appBar: AppBar(
          centerTitle: false,
          backgroundColor: AppPallete.primary,
          elevation: 0,
          toolbarHeight: 78,
          titleSpacing: 16,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'FlowPOS',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppPallete.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              BlocBuilder<UserBloc, UserState>(
                builder: (context, state) {
                  final name = state is UserLoggedIn
                      ? state.user.name
                      : 'Unknown';
                  return Text(
                    'Cashier: $name',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppPallete.onPrimary,
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            BlocBuilder<TableBloc, TableState>(
              builder: (context, tableState) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppPallete.surface,
                      foregroundColor: AppPallete.primary,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SelectTableMobilePage(),
                        ),
                      );
                    },
                    child: Text(
                      'Table T${tableState.selectedTableNumber}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppPallete.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
            IconButton(
              onPressed: () {
                context.read<AuthBloc>().add(SignOutEvent());
              },
              icon: const Icon(Icons.logout),
              color: AppPallete.onPrimary,
              tooltip: 'Logout',
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 86),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      color: AppPallete.primary,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: BlocBuilder<CategoryBloc, CategoryState>(
                        builder: (context, state) {
                          if (state is CategoryLoading) {
                            return const Text('Loading categories...');
                          } else if (state is CategoryFailure) {
                            return Text('Error: ${state.message}');
                          } else if (state is CategoryLoaded) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: state.categories
                                    .map(
                                      (category) => Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: _CategoryBadge(
                                          label: category.name,
                                          isSelected:
                                              _selectedCategory == category.id,
                                          onTap: () {
                                            setState(() {
                                              _selectedCategory = category.id;
                                            });
                                          },
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            );
                          } else {
                            return const SizedBox();
                          }
                        },
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: BlocConsumer<MenuItemBloc, MenuItemState>(
                          listener: (context, state) {
                            if (state is MenuItemFailure) {
                              showSnackbar(context, state.message);
                            }
                          },
                          builder: (context, state) {
                            if (state is MenuItemLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            } else if (state is MenuItemLoaded) {
                              final filteredItems = _selectedCategory == 'all'
                                  ? state.menuItems
                                  : state.menuItems
                                        .where(
                                          (item) =>
                                              item.category.id ==
                                              _selectedCategory,
                                        )
                                        .toList();

                              return RefreshIndicator(
                                onRefresh: () async {
                                  context.read<MenuItemBloc>().add(
                                    GetEnabledMenuItemsEvent(),
                                  );

                                  await Future.delayed(
                                    const Duration(seconds: 1),
                                  );
                                },
                                child: GridView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  itemCount: filteredItems.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        mainAxisSpacing: 12,
                                        crossAxisSpacing: 12,
                                        childAspectRatio: 0.78,
                                      ),
                                  itemBuilder: (context, index) {
                                    final item = filteredItems[index];

                                    return MenuItemCard(
                                      name: item.name,
                                      price: item.price,
                                      onAdd: () async {
                                        // Capture bloc references before async operation to avoid context warnings
                                        final cartBloc = context
                                            .read<CartBloc>();
                                        final modifierBloc = context
                                            .read<ModifierOptionBloc>();

                                        final result =
                                            await showDialog<
                                              Map<String, dynamic>
                                            >(
                                              context: context,
                                              builder: (_) =>
                                                  BlocProvider.value(
                                                    value: modifierBloc,
                                                    child: ModifierDialog(
                                                      menuId: item.id,
                                                      itemName: item.name,
                                                      price: item.price,
                                                    ),
                                                  ),
                                            );

                                        if (result != null) {
                                          cartBloc.add(
                                            AddToCartEvent(
                                              menuItemId: item.id,
                                              name: item.name,
                                              basePrice: item.price,
                                              quantity:
                                                  result['quantity'] as int,
                                              selectedModifiers:
                                                  result['selectedModifiers']
                                                      as Map<
                                                        String,
                                                        SelectedModifier?
                                                      >,
                                              totalPrice:
                                                  result['totalPrice'] as int,
                                            ),
                                          );
                                        }
                                      },
                                    );
                                  },
                                ),
                              );
                            } else {
                              return const Center(
                                child: Text("No Menu Items Available"),
                              );
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: BlocBuilder<CartBloc, CartState>(
                  builder: (context, cartState) {
                    final itemCount = cartState is CartLoaded
                        ? cartState.items.length
                        : 0;
                    final totalAmount = cartState is CartLoaded
                        ? cartState.totalAmount
                        : 0;

                    return Container(
                      color: AppPallete.surface,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: SafeArea(
                        top: false,
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: itemCount > 0
                                ? () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled:
                                          true, // WAJIB jika memiliki child yang bisa di-scroll
                                      backgroundColor: Colors.transparent,
                                      builder: (context) {
                                        return Container(
                                          height:
                                              MediaQuery.of(
                                                context,
                                              ).size.height *
                                              0.78,
                                          decoration: const BoxDecoration(
                                            color: AppPallete.surface,
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                          ),
                                          child: const Padding(
                                            padding: EdgeInsets.only(top: 8),
                                            child: ListOrderSection(),
                                          ),
                                        );
                                      },
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppPallete.primary,
                              foregroundColor: AppPallete.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              itemCount > 0
                                  ? 'View Cart ($itemCount) - Rp $totalAmount'
                                  : 'Cart is Empty',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppPallete.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryBadge({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppPallete.surface : AppPallete.primary,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppPallete.surface : AppPallete.onPrimary,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: isSelected ? AppPallete.primary : AppPallete.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
