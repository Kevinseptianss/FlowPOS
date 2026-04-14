import 'package:flow_pos/core/common/bloc/user_bloc.dart';
import 'package:flow_pos/core/services/cashier_shift_local_service.dart';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_logout_dialog.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/domain/entities/selected_modifier.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/floating_cart_bar.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/list_order_section.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/menu_item_card.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/widgets/modifier_dialog.dart';
import 'package:flow_pos/features/category/domain/entities/category.dart';
import 'package:flow_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/cart_bloc.dart';
import 'package:flow_pos/features/menu_item/presentation/bloc/menu_item_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/table_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/pages/select_table_mobile_page.dart';
import 'package:flow_pos/features/shift/presentation/pages/open_shift_page.dart';
import 'package:flow_pos/init_dependencies.dart';
import 'package:flow_pos/features/shift/presentation/bloc/shift_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class CashierMobilePage extends StatefulWidget {
  const CashierMobilePage({super.key});

  @override
  State<CashierMobilePage> createState() => _CashierMobilePageState();
}

class _CashierMobilePageState extends State<CashierMobilePage> {
  String _selectedCategory = 'all';
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier<String>('');
  final TextEditingController _searchController = TextEditingController();

  late final CategoryBloc _categoryBloc;
  late final MenuItemBloc _menuItemBloc;
  late final CashierShiftLocalService _cashierShiftLocalService;

  String? _cashierId;
  bool _isWarningBannerDismissed = false;

  @override
  void initState() {
    super.initState();
    _categoryBloc = context.read<CategoryBloc>();
    _menuItemBloc = context.read<MenuItemBloc>();
    _cashierShiftLocalService = serviceLocator<CashierShiftLocalService>();

    _categoryBloc.add(GetAllCategoriesEvent());
    _menuItemBloc.add(GetEnabledMenuItemsEvent());
    
    final userState = context.read<UserBloc>().state;
    if (userState is UserLoggedIn) {
      _cashierId = userState.user.id;
      // Fetch active shift from database on init
      context.read<ShiftBloc>().add(GetActiveShiftEvent(cashierId: _cashierId!));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
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
    final userState = context.watch<UserBloc>().state;
    final name = userState is UserLoggedIn ? userState.user.name : 'Unknown';
    final userId = userState is UserLoggedIn ? userState.user.id : '';

    return BlocBuilder<ShiftBloc, ShiftState>(
      builder: (context, shiftState) {
        final isProcessing = shiftState is ShiftLoading;
        final isSkipped = shiftState is ShiftSkipped || _cashierShiftLocalService.isShiftSkipped(userId);

        return MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthFailure) {
                  showSnackbar(context, state.message);
                }
              },
            ),
            BlocListener<ShiftBloc, ShiftState>(
              listener: (context, state) {
                if (state is ShiftNone) {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const OpenShiftPage()),
                  );
                } else if (state is ShiftClosed) {
                  showSnackbar(
                    context,
                    'Shift ditutup. Data berhasil disimpan ke database.',
                  );
                  // Refresh to show ShiftNone or check again
                  context.read<ShiftBloc>().add(GetActiveShiftEvent(cashierId: _cashierId!));
                } else if (state is ShiftFailure) {
                  showSnackbar(context, 'Gagal: ${state.message}');
                }
              },
            ),
          ],
          child: Scaffold(
            backgroundColor: AppPallete.background,
            body: Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Modern Personalized Header
                    SliverToBoxAdapter(
                      child: _buildHeader(
                        context,
                        name,
                        userId,
                        shiftState is ShiftOpened,
                        isProcessing,
                      ),
                    ),

                    // Sticky Categories Header
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _SliverCategoryDelegate(
                        child: Container(
                          height: 76,
                          color: AppPallete.background,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: BlocBuilder<CategoryBloc, CategoryState>(
                            builder: (context, state) {
                              if (state is CategoryLoaded) {
                                final displayCategories = [
                                  const Category(id: 'all', name: 'Semua'),
                                  ...state.categories,
                                ];
                                return SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: displayCategories.map((category) {
                                      final isSelected = _selectedCategory == category.id;
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: ChoiceChip(
                                          label: Text(category.name),
                                          selected: isSelected,
                                          onSelected: (val) {
                                            setState(() {
                                              _selectedCategory = category.id;
                                            });
                                          },
                                          selectedColor: AppPallete.primary,
                                          labelStyle: GoogleFonts.outfit(
                                            color: isSelected ? Colors.white : AppPallete.textPrimary,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          ),
                                          backgroundColor: Colors.white,
                                          elevation: isSelected ? 4 : 0,
                                          shadowColor: AppPallete.primary.withAlpha(50),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            side: BorderSide(
                                              color: isSelected ? AppPallete.primary : AppPallete.divider,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                    ),

                    // Warning Banner for Skipped Shift (Integrated as Sliver)
                    if (isSkipped && !_isWarningBannerDismissed)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.info_rounded, color: Colors.orange),
                                    const SizedBox(width: 8),
                                    const Expanded(
                                      child: Text(
                                        'Anda belum membuka shift hari ini.',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => setState(() => _isWarningBannerDismissed = true),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    _cashierShiftLocalService.clearShiftSkipped(userId);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => const OpenShiftPage()),
                                    );
                                  },
                                  child: const Text('Buka Shift Sekarang'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Menu Section
                    ValueListenableBuilder<String>(
                      valueListenable: _searchQueryNotifier,
                      builder: (context, searchQuery, _) {
                        return BlocBuilder<MenuItemBloc, MenuItemState>(
                          builder: (context, state) {
                            if (state is MenuItemLoading) {
                              return const SliverFillRemaining(
                                child: Center(child: CircularProgressIndicator()),
                              );
                            } else if (state is MenuItemLoaded) {
                              var filteredItems = state.menuItems;
                              
                              // Filter by Category
                              if (_selectedCategory != 'all') {
                                filteredItems = filteredItems.where((item) => item.category.id == _selectedCategory).toList();
                              }
                              
                              // Filter by Search
                              if (searchQuery.isNotEmpty) {
                                filteredItems = filteredItems.where((item) => item.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
                              }

                              if (filteredItems.isEmpty) {
                                return const SliverFillRemaining(
                                  child: Center(child: Text('Menu tidak ditemukan')),
                                );
                              }

                              return SliverPadding(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                                sliver: SliverGrid(
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 16,
                                    crossAxisSpacing: 16,
                                    childAspectRatio: 0.75,
                                  ),
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final item = filteredItems[index];
                                      return MenuItemCard(
                                        name: item.name,
                                        price: item.price,
                                        onQuickAdd: () {
                                          if (item.variants.isNotEmpty) {
                                            _showItemDetail(item);
                                          } else {
                                            context.read<CartBloc>().add(AddToCartEvent(
                                              menuItemId: item.id,
                                              name: item.name,
                                              basePrice: item.price,
                                              quantity: 1,
                                              selectedModifiers: const {},
                                              totalPrice: item.price,
                                              notes: '',
                                            ));
                                          }
                                        },
                                        onShowDetail: () => _showItemDetail(item),
                                      );
                                    },
                                    childCount: filteredItems.length,
                                  ),
                                ),
                              );
                            }
                            return const SliverFillRemaining(
                              child: Center(child: Text('Gagal memuat menu')),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),

                // Modern Floating Cart Bar
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 104,
                  child: FloatingCartBar(
                    onTap: () => _showCartSheet(false),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showItemDetail(dynamic item) async {
    final cartBloc = context.read<CartBloc>();
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ModifierDialog(
        menuId: item.id,
        itemName: item.name,
        price: item.price,
        variants: item.variants,
      ),
    );

    if (result != null && mounted) {
      cartBloc.add(AddToCartEvent(
        menuItemId: item.id,
        name: item.name,
        basePrice: item.price,
        quantity: (result['quantity'] as num).toInt(),
        selectedModifiers: result['selectedModifiers'] as Map<String, SelectedModifier?>,
        totalPrice: (result['totalPrice'] as num).toInt(),
        variantId: result['variantId'] as String?,
        notes: result['notes'] as String?,
      ));
    }
  }

  void _showCartSheet(bool isPayout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: AppPallete.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPallete.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListOrderSection(
                  isMobileCheckoutFlow: true,
                  isPayoutMode: isPayout,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    String name,
    String userId,
    bool hasActiveShift,
    bool isProcessing,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      decoration: const BoxDecoration(
        color: AppPallete.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Bekerja,',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (hasActiveShift)
                    BlocBuilder<TableBloc, TableState>(
                      builder: (context, tableState) {
                        final tableNum = tableState.selectedTableNumber;
                        final isTakeaway = tableNum == 0;
                        
                        return InkWell(
                          onTap: () async {
                            final result = await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const SelectTableMobilePage(),
                              ),
                            );

                            if (result == 'PAYOUT' && mounted) {
                              // Small delay to ensure bloc listeners in parent (CashierPage) have synced the cart
                              await Future.delayed(const Duration(milliseconds: 100));
                              if (mounted) _showCartSheet(true);
                            } else if (result == 'ADD' && mounted) {
                              // Ensure any automatic sync from parent is cleared so user starts with fresh cart
                              await Future.delayed(const Duration(milliseconds: 150));
                              if (mounted) context.read<CartBloc>().add(const ClearCartEvent());
                            }
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white.withAlpha(60)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isTakeaway ? Icons.local_mall_rounded : Icons.table_restaurant_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isTakeaway ? 'Takeaway' : 'Meja T$tableNum',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  else
                    _buildHeaderAction(
                      icon: Icons.logout_rounded,
                      onTap: _logout,
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Modern Search Bar
          Container(
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppPallete.textSecondary),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _searchQueryNotifier.value = val,
                    decoration: InputDecoration(
                      hintText: 'Cari menu lezat Anda...',
                      hintStyle: GoogleFonts.outfit(color: AppPallete.textSecondary),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                ValueListenableBuilder<String>(
                  valueListenable: _searchQueryNotifier,
                  builder: (context, query, _) {
                    if (query.isEmpty) return const SizedBox.shrink();
                    return IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        _searchQueryNotifier.value = '';
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderAction({
    IconData? icon,
    required VoidCallback onTap,
    Color? color,
    Widget? child,
  }) {
    return Material(
      color: color ?? Colors.white.withAlpha(40),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: child ?? (icon != null ? Icon(icon, color: Colors.white, size: 24) : const SizedBox.shrink()),
        ),
      ),
    );
  }
}

class _SliverCategoryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _SliverCategoryDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 76;
  @override
  double get minExtent => 76;

  @override
  bool shouldRebuild(covariant _SliverCategoryDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
