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
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppPallete.textPrimary.withAlpha(127)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Menu Management',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AddMenuDialog(),
                  );
                },
                child: Container(
                  padding: EdgeInsetsGeometry.all(5),
                  decoration: BoxDecoration(
                    color: AppPallete.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.add, color: AppPallete.onPrimary),
                ),
              ),
            ],
          ),
        ),
        // Menu List
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12),
            child: BlocBuilder<MenuItemBloc, MenuItemState>(
              builder: (context, state) {
                if (state is MenuItemLoading) {
                  return Center(child: CircularProgressIndicator());
                } else if (state is MenuItemFailure) {
                  return Center(
                    child: Text(
                      'Failed to load menu items',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  );
                } else if (state is MenuItemLoaded) {
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<MenuItemBloc>().add(GetAllMenuItemsEvent());

                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: state.menuItems.length,
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
        ),
      ],
    );
  }
}
