import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/menu_item/presentation/bloc/menu_item_bloc.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_menu_item_detail_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/add_menu_dialog.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/widgets/menu_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ManageMenuSection extends StatefulWidget {
  const ManageMenuSection({super.key});

  @override
  State<ManageMenuSection> createState() => _ManageMenuSectionState();
}

class _ManageMenuSectionState extends State<ManageMenuSection> {
  late final MenuItemBloc _menuItemBloc;

  @override
  void initState() {
    super.initState();
    _menuItemBloc = context.read<MenuItemBloc>();
    _menuItemBloc.add(GetAllMenuItemsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manajemen Menu',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => const AddMenuDialog(),
                    );
                  },
                  icon: const Icon(Icons.add_circle, color: AppPallete.primary, size: 32),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Menu List
          Expanded(
            child: BlocBuilder<MenuItemBloc, MenuItemState>(
              builder: (context, state) {
                if (state is MenuItemLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is MenuItemFailure) {
                  return Center(
                    child: Text(
                      'Gagal memuat menu',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppPallete.error,
                          ),
                    ),
                  );
                } else if (state is MenuItemLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<MenuItemBloc>().add(GetAllMenuItemsEvent());
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.menuItems.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final menuItem = state.menuItems[index];
                        return MenuCard(
                          key: ValueKey(menuItem.id),
                          title: menuItem.name,
                          price: menuItem.price,
                          category: menuItem.category.name,
                          enabled: menuItem.enabled,
                          onTap: () {
                            Navigator.push(
                              context,
                              OwnerMenuItemDetailPage.route(menuItem),
                            );
                          },
                          onEnabledChanged: (value) {
                            context.read<MenuItemBloc>().add(
                                  UpdateMenuItemAvailabilityEvent(
                                    menuItemId: menuItem.id,
                                    enabled: value,
                                  ),
                                );
                          },
                          image: Image.asset('assets/images/default-food.jpg'),
                        );
                      },
                    ),
                  );
                }

                return const SizedBox();
              },
            ),
          ),
        ],
      ),
    );
  }
}
