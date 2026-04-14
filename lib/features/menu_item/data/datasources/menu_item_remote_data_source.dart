import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/menu_item/data/models/menu_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract interface class MenuItemRemoteDataSource {
  Future<List<MenuItemModel>> getAllMenuItems();
  Future<List<MenuItemModel>> getEnabledMenuItems();
  Future<MenuItemModel> createMenuItem({
    required String name,
    required int price,
    required int basePrice,
    required String categoryId,
    required String unit,
    required bool enabled,
    required List<Map<String, dynamic>> options,
  });
  Future<MenuItemModel> updateMenuItemAvailability({
    required String menuItemId,
    required bool enabled,
  });
  Future<MenuItemModel> updateMenuItem({
    required String id,
    required String name,
    required int price,
    required int basePrice,
    required String categoryId,
    required String unit,
    required bool enabled,
    required List<Map<String, dynamic>> options,
  });
}

class MenuItemRemoteDataSourceImpl implements MenuItemRemoteDataSource {
  final SupabaseClient supabaseClient;
  final Uuid _uuid = const Uuid();

  MenuItemRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<MenuItemModel>> getAllMenuItems() async {
    try {
      final response = await supabaseClient
          .from('menu_items')
          .select("*, categories!category_id(id, name), menu_item_variants(*)")
          .order('name', ascending: true);

      return response
          .map((menuItem) => MenuItemModel.fromJson(menuItem))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<MenuItemModel>> getEnabledMenuItems() async {
    try {
      final response = await supabaseClient
          .from('menu_items')
          .select("*, categories!category_id(id, name), menu_item_variants(*)")
          .eq('is_available', true)
          .order('name', ascending: true);

      return response
          .map((menuItem) => MenuItemModel.fromJson(menuItem))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<MenuItemModel> createMenuItem({
    required String name,
    required int price,
    required int basePrice,
    required String categoryId,
    required String unit,
    required bool enabled,
    required List<Map<String, dynamic>> options,
  }) async {
    try {
      final menuItemId = _uuid.v4();
      
      await supabaseClient.from('menu_items').insert({
        'id': menuItemId,
        'name': name,
        'price': price,
        'base_price': basePrice,
        'category_id': categoryId,
        'unit': unit,
        'is_available': enabled,
      });

      if (options.isNotEmpty) {
        final List<Map<String, dynamic>> variantPayload = [];
        
        for (final option in options) {
          final optionName = option['option_name'] as String;
          final variants = option['variants'] as List<dynamic>;
          
          for (final variant in variants) {
            variantPayload.add({
              'id': _uuid.v4(),
              'menu_item_id': menuItemId,
              'option_name': optionName,
              'variant_name': variant['name'] as String,
              'price': (variant['price'] as num).toInt(),
              'base_price': (variant['base_price'] as num?)?.toInt() ?? 0,
              'unit': variant['unit'] as String,
            });
          }
        }

        if (variantPayload.isNotEmpty) {
          await supabaseClient.from('menu_item_variants').insert(variantPayload);
        }
      }

      final menuItem = await supabaseClient
          .from('menu_items')
          .select('*, categories!category_id(id, name), menu_item_variants(*)')
          .eq('id', menuItemId)
          .single();

      return MenuItemModel.fromJson(menuItem);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<MenuItemModel> updateMenuItemAvailability({
    required String menuItemId,
    required bool enabled,
  }) async {
    try {
      final response = await supabaseClient
          .from('menu_items')
          .update({'is_available': enabled})
          .eq('id', menuItemId)
          .select("*, categories!category_id(id, name), menu_item_variants(*)")
          .single();

      return MenuItemModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<MenuItemModel> updateMenuItem({
    required String id,
    required String name,
    required int price,
    required int basePrice,
    required String categoryId,
    required String unit,
    required bool enabled,
    required List<Map<String, dynamic>> options,
  }) async {
    try {
      // 1. Update main record
      await supabaseClient.from('menu_items').update({
        'name': name,
        'price': price,
        'base_price': basePrice,
        'category_id': categoryId,
        'unit': unit,
        'is_available': enabled,
      }).eq('id', id);

      // 2. Delete existing variants
      await supabaseClient
          .from('menu_item_variants')
          .delete()
          .eq('menu_item_id', id);

      // 3. Insert new variants
      if (options.isNotEmpty) {
        final List<Map<String, dynamic>> variantPayload = [];
        for (final option in options) {
          final optionName = option['option_name'] as String;
          final variants = option['variants'] as List<dynamic>;

          for (final variant in variants) {
            variantPayload.add({
              'id': _uuid.v4(),
              'menu_item_id': id,
              'option_name': optionName,
              'variant_name': variant['name'] as String,
              'price': (variant['price'] as num).toInt(),
              'base_price': (variant['base_price'] as num?)?.toInt() ?? 0,
              'unit': variant['unit'] as String,
            });
          }
        }

        if (variantPayload.isNotEmpty) {
          await supabaseClient
              .from('menu_item_variants')
              .insert(variantPayload);
        }
      }

      // 4. Return updated record
      final response = await supabaseClient
          .from('menu_items')
          .select("*, categories!category_id(id, name), menu_item_variants(*)")
          .eq('id', id)
          .single();

      return MenuItemModel.fromJson(response);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
