import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/modifier_option/data/models/modifier_option_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class ModifierOptionRemoteDataSource {
  Future<List<ModifierOptionModel>> getAllModifierOptionsByMenuId(
    String menuId,
  );
}

class ModifierOptionRemoteDataSourceImpl
    implements ModifierOptionRemoteDataSource {
  final SupabaseClient supabaseClient;

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
}
