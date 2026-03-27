import 'dart:async';

import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/menu_item/data/models/menu_item_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

abstract interface class MenuItemRemoteDataSource {
  Future<List<MenuItemModel>> getAllMenuItems();
  Future<List<MenuItemModel>> getEnabledMenuItems();
  Stream<List<MenuItemModel>> listenAllMenuItems();
  Stream<List<MenuItemModel>> listenEnabledMenuItems();
  Future<MenuItemModel> createMenuItem({
    required String name,
    required int price,
    required String categoryId,
  });
  Future<MenuItemModel> updateMenuItemAvailability({
    required String menuItemId,
    required bool enabled,
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
  Future<List<MenuItemModel>> getEnabledMenuItems() async {
    try {
      final response = await supabaseClient
          .from('menu_items')
          .select("*, categories!category_id(id, name)")
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
  Stream<List<MenuItemModel>> listenAllMenuItems() {
    final menuItemsStream = supabaseClient
        .from('menu_items')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true);
    final categoriesStream = supabaseClient
        .from('categories')
        .stream(primaryKey: ['id']);

    final controller = StreamController<List<MenuItemModel>>();

    List<Map<String, dynamic>> latestMenuRows = const [];
    List<Map<String, dynamic>> latestCategoryRows = const [];

    void emitCombined() {
      final categoryById = <String, Map<String, dynamic>>{};
      for (final categoryRow in latestCategoryRows) {
        final id = categoryRow['id'] as String?;
        if (id != null) {
          categoryById[id] = categoryRow;
        }
      }

      final menuItems = latestMenuRows
          .map(
            (row) => MenuItemModel.fromJson({
              ...row,
              'categories':
                  categoryById[row['category_id'] as String? ?? ''] ?? const {},
            }),
          )
          .toList();

      controller.add(menuItems);
    }

    late final StreamSubscription<List<Map<String, dynamic>>> menuItemsSub;
    late final StreamSubscription<List<Map<String, dynamic>>> categoriesSub;

    menuItemsSub = menuItemsStream.listen((rows) {
      latestMenuRows = rows;
      emitCombined();
    }, onError: controller.addError);

    categoriesSub = categoriesStream.listen((rows) {
      latestCategoryRows = rows;
      emitCombined();
    }, onError: controller.addError);

    controller.onCancel = () async {
      await menuItemsSub.cancel();
      await categoriesSub.cancel();
    };

    return controller.stream;
  }

  @override
  Stream<List<MenuItemModel>> listenEnabledMenuItems() {
    final menuItemsStream = supabaseClient
        .from('menu_items')
        .stream(primaryKey: ['id'])
        .order('name', ascending: true);
    final categoriesStream = supabaseClient
        .from('categories')
        .stream(primaryKey: ['id']);

    final controller = StreamController<List<MenuItemModel>>();

    List<Map<String, dynamic>> latestMenuRows = const [];
    List<Map<String, dynamic>> latestCategoryRows = const [];

    void emitCombined() {
      final categoryById = <String, Map<String, dynamic>>{};
      for (final categoryRow in latestCategoryRows) {
        final id = categoryRow['id'] as String?;
        if (id != null) {
          categoryById[id] = categoryRow;
        }
      }

      final menuItems = latestMenuRows
          .where((row) => row['is_available'] == true)
          .map(
            (row) => MenuItemModel.fromJson({
              ...row,
              'categories':
                  categoryById[row['category_id'] as String? ?? ''] ?? const {},
            }),
          )
          .toList();

      controller.add(menuItems);
    }

    late final StreamSubscription<List<Map<String, dynamic>>> menuItemsSub;
    late final StreamSubscription<List<Map<String, dynamic>>> categoriesSub;

    menuItemsSub = menuItemsStream.listen((rows) {
      latestMenuRows = rows;
      emitCombined();
    }, onError: controller.addError);

    categoriesSub = categoriesStream.listen((rows) {
      latestCategoryRows = rows;
      emitCombined();
    }, onError: controller.addError);

    controller.onCancel = () async {
      await menuItemsSub.cancel();
      await categoriesSub.cancel();
    };

    return controller.stream;
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

  @override
  Future<MenuItemModel> updateMenuItemAvailability({
    required String menuItemId,
    required bool enabled,
  }) async {
    try {
      final menuItem = await supabaseClient
          .from('menu_items')
          .update({'is_available': enabled})
          .eq('id', menuItemId)
          .select('*, categories!category_id(id, name)')
          .single();

      return MenuItemModel.fromJson(menuItem);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
