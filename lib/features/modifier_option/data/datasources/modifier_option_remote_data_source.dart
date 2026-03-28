import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/modifier_option/data/models/modifier_option_model.dart';
import 'package:flow_pos/features/modifier_option/domain/entities/create_modifier_option_input.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract interface class ModifierOptionRemoteDataSource {
  Future<List<ModifierOptionModel>> getAllModifierOptionsByMenuId(
    String menuId,
  );
  Future<List<ModifierOptionModel>> getAllModifierOptions();
  Future<void> createModifierGroupWithOptions({
    required String groupName,
    required List<CreateModifierOptionInput> options,
  });
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
  Future<void> createModifierGroupWithOptions({
    required String groupName,
    required List<CreateModifierOptionInput> options,
  }) async {
    String? createdGroupId;

    try {
      final groupId = _uuid.v4();
      createdGroupId = groupId;

      await supabaseClient.from('modifier_groups').insert({
        'id': groupId,
        'name': groupName,
      });

      if (options.isEmpty) {
        return;
      }

      await _insertModifierOptions(groupId: groupId, options: options);
    } catch (e) {
      // If option insert fails after group creation, remove the new group to avoid orphan data.
      if (createdGroupId != null) {
        try {
          await supabaseClient
              .from('modifier_groups')
              .delete()
              .eq('id', createdGroupId);
        } catch (_) {}
      }

      throw ServerException(e.toString());
    }
  }

  Future<void> _insertModifierOptions({
    required String groupId,
    required List<CreateModifierOptionInput> options,
  }) async {
    final candidateGroupColumns = <String>[
      'modifier_group_id',
      'group_id',
      'modifier_id',
    ];

    PostgrestException? lastSchemaError;

    for (final groupColumn in candidateGroupColumns) {
      final payload = options
          .map(
            (option) => {
              'id': _uuid.v4(),
              groupColumn: groupId,
              'name': option.name,
              'additional_price': option.additionalPrice,
            },
          )
          .toList();

      try {
        await supabaseClient.from('modifier_options').insert(payload);
        return;
      } on PostgrestException catch (e) {
        final message = e.message.toLowerCase();
        final missingColumn =
            message.contains('could not find the') &&
            message.contains('column') &&
            message.contains(groupColumn);

        if (missingColumn) {
          lastSchemaError = e;
          continue;
        }

        rethrow;
      }
    }

    if (lastSchemaError != null) {
      throw ServerException(lastSchemaError.toString());
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
