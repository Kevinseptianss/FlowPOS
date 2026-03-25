import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/menu_item/data/models/menu_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract interface class MenuItemRemoteDataSource {
  Future<List<MenuItemModel>> getAllMenuItems();
  Future<MenuItemModel> createMenuItem({
    required String name,
    required int price,
    required String categoryId,
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
          .select("*, categories!category_id(id, name)")
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
    required String categoryId,
  }) async {
    try {
      final insertedMenuItem = await supabaseClient
          .from('menu_items')
          .insert({
            'id': _uuid.v4(),
            'name': name,
            'price': price,
            'category_id': categoryId,
            'is_available': true,
          })
          .select('id')
          .single();

      final menuItemId = insertedMenuItem['id'] as String;

      final menuItem = await supabaseClient
          .from('menu_items')
          .select('*, categories!category_id(id, name)')
          .eq('id', menuItemId)
          .single();

      return MenuItemModel.fromJson(menuItem);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
