import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/modifier_option/data/models/modifier_option_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract interface class ModifierOptionRemoteDataSource {
  Future<List<ModifierOptionModel>> getAllModifierOptionsByMenuId(
    String menuId,
  );
  Future<List<ModifierOptionModel>> getAllModifierOptions();
  Future<Set<String>> getSelectedModifierGroupIdsByMenuId(String menuId);
  Future<void> updateMenuModifierGroupMappings({
    required String menuId,
    required Set<String> modifierGroupIds,
  });
}

class ModifierOptionRemoteDataSourceImpl
    implements ModifierOptionRemoteDataSource {
  final SupabaseClient supabaseClient;
  final Uuid _uuid = const Uuid();

  ModifierOptionRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<ModifierOptionModel>> getAllModifierOptionsByMenuId(
    String menuId,
  ) async {
    try {
      final mappings = await supabaseClient
          .from('menu_modifier_mappings')
          .select('modifier_group_id')
          .eq('menu_item_id', menuId);

      final groupIds = mappings
          .map((mapping) => mapping['modifier_group_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();

      if (groupIds.isEmpty) {
        return [];
      }

      final groups = await supabaseClient
          .from('modifier_groups')
          .select('id, name, modifier_options(id, name, additional_price)')
          .inFilter('id', groupIds)
          .order('name', ascending: true);

      final result = <ModifierOptionModel>[];

      for (final group in groups) {
        final groupId = group['id'] as String? ?? '';
        final groupName = group['name'] as String? ?? '';
        final options = (group['modifier_options'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        for (final option in options) {
          result.add(
            ModifierOptionModel.fromJson(
              option,
              modifierGroupId: groupId,
              modifierGroupName: groupName,
            ),
          );
        }
      }

      return result;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<ModifierOptionModel>> getAllModifierOptions() async {
    try {
      final groups = await supabaseClient
          .from('modifier_groups')
          .select('id, name, modifier_options(id, name, additional_price)')
          .order('name', ascending: true);

      final result = <ModifierOptionModel>[];

      for (final group in groups) {
        final groupId = group['id'] as String? ?? '';
        final groupName = group['name'] as String? ?? '';
        final options = (group['modifier_options'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        for (final option in options) {
          result.add(
            ModifierOptionModel.fromJson(
              option,
              modifierGroupId: groupId,
              modifierGroupName: groupName,
            ),
          );
        }
      }

      return result;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Set<String>> getSelectedModifierGroupIdsByMenuId(String menuId) async {
    try {
      final mappings = await supabaseClient
          .from('menu_modifier_mappings')
          .select('modifier_group_id')
          .eq('menu_item_id', menuId);

      return mappings
          .map((mapping) => mapping['modifier_group_id'] as String?)
          .whereType<String>()
          .toSet();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> updateMenuModifierGroupMappings({
    required String menuId,
    required Set<String> modifierGroupIds,
  }) async {
    try {
      await supabaseClient
          .from('menu_modifier_mappings')
          .delete()
          .eq('menu_item_id', menuId);

      if (modifierGroupIds.isEmpty) {
        return;
      }

      final payload = modifierGroupIds
          .map(
            (groupId) => {
              'id': _uuid.v4(),
              'menu_item_id': menuId,
              'modifier_group_id': groupId,
            },
          )
          .toList();

      await supabaseClient.from('menu_modifier_mappings').insert(payload);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
