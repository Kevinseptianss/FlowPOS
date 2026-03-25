import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/menu_item/data/models/menu_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class MenuItemRemoteDataSource {
  Future<List<MenuItemModel>> getAllMenuItems();
}

class MenuItemRemoteDataSourceImpl implements MenuItemRemoteDataSource {
  final SupabaseClient supabaseClient;

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
}
