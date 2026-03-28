import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';
import 'package:flow_pos/features/modifier_option/domain/entities/modifier_option.dart';
import 'package:flow_pos/features/modifier_option/domain/usecases/update_menu_modifier_groups.dart';
import 'package:flow_pos/features/modifier_option/presentation/bloc/modifier_option_bloc.dart';
import 'package:flow_pos/init_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class OwnerMenuItemDetailPage extends StatefulWidget {
  final MenuItem menuItem;

  const OwnerMenuItemDetailPage({super.key, required this.menuItem});

  static MaterialPageRoute route(MenuItem menuItem) => MaterialPageRoute(
    builder: (context) => OwnerMenuItemDetailPage(menuItem: menuItem),
  );

  @override
  State<OwnerMenuItemDetailPage> createState() =>
      _OwnerMenuItemDetailPageState();
}

class _OwnerMenuItemDetailPageState extends State<OwnerMenuItemDetailPage> {
  final Set<String> _selectedModifierGroupIds = <String>{};
  String? _seededMenuId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    context.read<ModifierOptionBloc>().add(
      GetModifierGroupSelectionEvent(menuId: widget.menuItem.id),
    );
  }

  Future<void> _onGroupCheckedChanged({
    required String groupId,
    required bool checked,
  }) async {
    final previousSelected = Set<String>.from(_selectedModifierGroupIds);

    setState(() {
      _isSaving = true;
      if (checked) {
        _selectedModifierGroupIds.add(groupId);
      } else {
        _selectedModifierGroupIds.remove(groupId);
      }
    });

    final result = await serviceLocator<UpdateMenuModifierGroups>()(
      UpdateMenuModifierGroupsParams(
        menuId: widget.menuItem.id,
        modifierGroupIds: Set<String>.from(_selectedModifierGroupIds),
      ),
    );

    if (!mounted) {
      return;
    }

    result.fold(
      (failure) {
        setState(() {
          _isSaving = false;
          _selectedModifierGroupIds
            ..clear()
            ..addAll(previousSelected);
        });
        showSnackbar(context, failure.message);
      },
      (_) {
        setState(() {
          _isSaving = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Menu Detail',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(color: AppPallete.onPrimary),
        ),
      ),
      body: BlocBuilder<ModifierOptionBloc, ModifierOptionState>(
        builder: (context, state) {
          if (state is ModifierOptionInitial ||
              state is ModifierOptionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ModifierOptionFailure) {
            return Center(
              child: Text(
                state.message,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppPallete.error),
              ),
            );
          }

          if (state is ModifierOptionLoaded) {
            return const SizedBox();
          }

          if (state is ModifierGroupSelectionLoaded) {
            if (state.menuId != widget.menuItem.id) {
              return const Center(child: CircularProgressIndicator());
            }

            final groupedOptions = <String, List<ModifierOption>>{};
            final groupNames = <String, String>{};

            for (final option in state.modifierOptions) {
              groupedOptions
                  .putIfAbsent(option.modifierGroupId, () => [])
                  .add(option);
              groupNames[option.modifierGroupId] = option.modifierGroupName;
            }

            if (_seededMenuId != state.menuId) {
              _selectedModifierGroupIds
                ..clear()
                ..addAll(state.selectedModifierGroupIds);
              _seededMenuId = state.menuId;
            }

            final selectedGroupNames = groupedOptions.keys
                .where((groupId) => _selectedModifierGroupIds.contains(groupId))
                .map((groupId) => groupNames[groupId] ?? 'Modifier')
                .toList();

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    children: [
                      _SectionCard(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/default-food.jpg',
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.menuItem.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          color: AppPallete.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    formatRupiah(widget.menuItem.price),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppPallete.textPrimary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppPallete.background,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppPallete.divider,
                                      ),
                                    ),
                                    child: Text(
                                      widget.menuItem.category.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: AppPallete.textPrimary,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        widget.menuItem.enabled
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: widget.menuItem.enabled
                                            ? AppPallete.success
                                            : AppPallete.error,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        widget.menuItem.enabled
                                            ? 'Available'
                                            : 'Unavailable',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: AppPallete.textPrimary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SectionCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modifier Groups',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: AppPallete.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Check a modifier group to connect it with this menu item. Options inside the group will follow automatically.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppPallete.textPrimary),
                            ),
                            const SizedBox(height: 14),
                            if (groupedOptions.isEmpty)
                              Text(
                                'No modifier groups available.',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppPallete.textPrimary),
                              )
                            else
                              ...groupedOptions.entries.expand((entry) {
                                final groupId = entry.key;
                                final options = entry.value;
                                final groupName =
                                    groupNames[groupId] ?? 'Modifier';

                                return [
                                  CheckboxListTile(
                                    value: _selectedModifierGroupIds.contains(
                                      groupId,
                                    ),
                                    contentPadding: EdgeInsets.zero,
                                    activeColor: AppPallete.primary,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(
                                      groupName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(
                                            color: AppPallete.textPrimary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    subtitle: Text(
                                      '${options.length} option(s)',
                                    ),
                                    onChanged: _isSaving
                                        ? null
                                        : (value) {
                                            _onGroupCheckedChanged(
                                              groupId: groupId,
                                              checked: value ?? false,
                                            );
                                          },
                                  ),
                                  const SizedBox(height: 2),
                                  ...options.map((option) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16,
                                        bottom: 8,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('- '),
                                          Expanded(
                                            child: Text(
                                              '${option.name} (+${formatRupiah(option.additionalPrice)})',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        AppPallete.textPrimary,
                                                  ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  const SizedBox(height: 12),
                                ];
                              }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: AppPallete.surface,
                    border: Border(top: BorderSide(color: AppPallete.divider)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selected Modifier',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppPallete.textPrimary),
                          ),
                          Text(
                            '${_selectedModifierGroupIds.length}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppPallete.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (selectedGroupNames.isEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'No modifier group selected.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppPallete.textPrimary),
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedGroupNames
                              .map(
                                (name) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppPallete.background,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: AppPallete.divider,
                                    ),
                                  ),
                                  child: Text(
                                    name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                          color: AppPallete.textPrimary,
                                        ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                    ],
                  ),
                ),
              ],
            );
          }

          return const SizedBox();
        },
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPallete.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPallete.divider),
      ),
      child: child,
    );
  }
}
