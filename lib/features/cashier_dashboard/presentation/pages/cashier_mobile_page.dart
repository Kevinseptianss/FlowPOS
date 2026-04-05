import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/services/cashier_shift_local_service.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_logout_dialog.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/domain/entities/selected_modifier.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/table_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/select_table_mobile_page.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/list_order_section.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/cashier_shift_dialogs.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/menu_item_card.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/modifier_dialog.dart';
import 'package:flow_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/cart_bloc.dart';
import 'package:flow_pos/features/menu_item/presentation/bloc/menu_item_bloc.dart';
import 'package:flow_pos/features/modifier_option/presentation/bloc/modifier_option_bloc.dart';
import 'package:flow_pos/features/order/domain/usecases/get_all_orders.dart';
import 'package:flow_pos/init_dependencies.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CashierMobilePage extends StatefulWidget {
  const CashierMobilePage({super.key});

  @override
  State<CashierMobilePage> createState() => _CashierMobilePageState();
}

class _CashierMobilePageState extends State<CashierMobilePage> {
  String _selectedCategory = 'all';
  late final CategoryBloc _categoryBloc;
  late final MenuItemBloc _menuItemBloc;
  late final CashierShiftLocalService _cashierShiftLocalService;
  late final GetAllOrders _getAllOrders;

  bool _isShiftActive = false;
  bool _isShiftReady = false;
  bool _isProcessingShiftAction = false;
  String? _cashierId;

  @override
  void initState() {
    super.initState();
    _categoryBloc = context.read<CategoryBloc>();
    _menuItemBloc = context.read<MenuItemBloc>();
    _cashierShiftLocalService = serviceLocator<CashierShiftLocalService>();
    _getAllOrders = serviceLocator<GetAllOrders>();

    _categoryBloc.add(GetAllCategoriesEvent());
    _menuItemBloc.add(GetEnabledMenuItemsEvent());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapShiftState();
    });
  }

  Future<void> _bootstrapShiftState() async {
    final userState = context.read<UserBloc>().state;
    if (userState is! UserLoggedIn) {
      return;
    }

    _cashierId = userState.user.id;
    final hasActiveShift = _cashierShiftLocalService.hasActiveShift(
      userState.user.id,
    );

    if (hasActiveShift) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isShiftActive = true;
        _isShiftReady = true;
      });

      return;
    }

    final openingBalance = await showOpeningBalanceDialog(
      context,
      cashierName: userState.user.name,
    );

    await _cashierShiftLocalService.openShift(
      cashierId: userState.user.id,
      cashierName: userState.user.name,
      openingBalance: openingBalance,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isShiftActive = true;
      _isShiftReady = true;
    });

    showSnackbar(
      context,
      'Shift aktif. Modal awal tersimpan di local database.',
    );
  }

  Future<void> _closeShift() async {
    if (_cashierId == null || _isProcessingShiftAction) {
      return;
    }

    final activeShift = _cashierShiftLocalService.getActiveShift(_cashierId!);
    if (activeShift == null) {
      setState(() {
        _isShiftActive = false;
      });
      return;
    }

    final openingBalance =
        (activeShift['openingBalance'] as num?)?.toDouble() ?? 0;
    final openedAt = DateTime.tryParse(
      activeShift['openedAt'] as String? ?? '',
    );
    final confirmed = await showCloseShiftDialog(
      context,
      openingBalance: openingBalance,
      openedAt: openedAt ?? DateTime.now(),
    );

    if (!confirmed || !mounted) {
      return;
    }

    setState(() {
      _isProcessingShiftAction = true;
    });

    final closedShift = await _cashierShiftLocalService.closeShift(
      cashierId: _cashierId!,
    );

    if (closedShift != null && openedAt != null) {
      final closedAt = DateTime.tryParse(
        closedShift['closedAt'] as String? ?? '',
      );

      if (closedAt != null) {
        await _printShiftOrderItemsToDebugConsole(
          openedAt: openedAt,
          closedAt: closedAt,
        );
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isShiftActive = false;
      _isProcessingShiftAction = false;
    });

    showSnackbar(
      context,
      'Shift ditutup. Data tersimpan lokal dan siap dikirim ke database.',
    );
  }

  Future<void> _printShiftOrderItemsToDebugConsole({
    required DateTime openedAt,
    required DateTime closedAt,
  }) async {
    final result = await _getAllOrders(NoParams());

    result.fold(
      (failure) {
        debugPrint(
          '[ShiftClose] Failed to load orders for shift logging: ${failure.message}',
        );
      },
      (orders) {
        final openedAtLocal = openedAt.toLocal();
        final closedAtLocal = closedAt.toLocal();

        final ordersInShift = orders.where((order) {
          final orderTime = order.createdAt.toLocal();
          return !orderTime.isBefore(openedAtLocal) &&
              !orderTime.isAfter(closedAtLocal);
        }).toList();

        if (ordersInShift.isEmpty) {
          debugPrint(
            '[ShiftClose] No orders found between ${openedAtLocal.toIso8601String()} and ${closedAtLocal.toIso8601String()}.',
          );
          return;
        }

        debugPrint(
          '[ShiftClose] Orders between ${openedAtLocal.toIso8601String()} and ${closedAtLocal.toIso8601String()}:',
        );

        for (final order in ordersInShift) {
          debugPrint(
            '[ShiftClose] Order ${order.orderNumber} at ${order.createdAt.toLocal().toIso8601String()}',
          );

          for (final item in order.items) {
            debugPrint(
              '[ShiftClose]  - ${item.menuName} x${item.quantity} @ ${item.unitPrice}',
            );
          }
        }
      },
    );
  }

  Future<void> _logout() async {
    final shouldLogout = await showLogoutDialog(
      context,
      accountLabel: 'cashier account',
    );

    if (!mounted || !shouldLogout) {
      return;
    }

    context.read<AuthBloc>().add(SignOutEvent());
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
            if (!_isShiftReady)
              const Padding(
                padding: EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppPallete.onPrimary,
                  ),
                ),
              )
            else if (_isShiftActive)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPallete.warning,
                    foregroundColor: AppPallete.onPrimary,
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: _isProcessingShiftAction ? null : _closeShift,
                  icon: const Icon(Icons.lock_clock_rounded),
                  label: const Text('Tutup Kasir'),
                ),
              )
            else
              IconButton(
                onPressed: _logout,
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
