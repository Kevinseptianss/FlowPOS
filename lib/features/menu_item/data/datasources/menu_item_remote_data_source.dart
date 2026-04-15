import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/menu_item/data/models/menu_item_model.dart';

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
  final FirebaseFirestore _firestore;

  MenuItemRemoteDataSourceImpl(this._firestore);

  @override
  Future<List<MenuItemModel>> getAllMenuItems() async {
    try {
      final snapshot = await _firestore
          .collection('menu_items')
          .orderBy('name', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => _mapToModel(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<MenuItemModel>> getEnabledMenuItems() async {
    try {
      final snapshot = await _firestore
          .collection('menu_items')
          .where('is_available', isEqualTo: true)
          .orderBy('name', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => _mapToModel(doc.id, doc.data()))
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
      final docRef = _firestore.collection('menu_items').doc();
      
      // Get category name for denormalization
      final catDoc = await _firestore.collection('categories').doc(categoryId).get();
      final categoryName = catDoc.exists ? (catDoc.data()?['name'] ?? 'Unknown') : 'Unknown';

      final variants = _processOptions(options);

      final data = {
        'id': docRef.id,
        'name': name,
        'price': price,
        'base_price': basePrice,
        'category_id': categoryId,
        'category_name': categoryName,
        'unit': unit,
        'is_available': enabled,
        'menu_item_variants': variants,
        'created_at': FieldValue.serverTimestamp(),
      };

      await docRef.set(data);

      return _mapToModel(docRef.id, data);
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
      await _firestore
          .collection('menu_items')
          .doc(menuItemId)
          .update({'is_available': enabled});

      final doc = await _firestore.collection('menu_items').doc(menuItemId).get();
      return _mapToModel(doc.id, doc.data()!);
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
      final catDoc = await _firestore.collection('categories').doc(categoryId).get();
      final categoryName = catDoc.exists ? (catDoc.data()?['name'] ?? 'Unknown') : 'Unknown';

      final variants = _processOptions(options);

      final data = {
        'name': name,
        'price': price,
        'base_price': basePrice,
        'category_id': categoryId,
        'category_name': categoryName,
        'unit': unit,
        'is_available': enabled,
        'menu_item_variants': variants,
        'updated_at': FieldValue.serverTimestamp(),
      };

      await _firestore.collection('menu_items').doc(id).update(data);

      final doc = await _firestore.collection('menu_items').doc(id).get();
      return _mapToModel(doc.id, doc.data()!);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  List<Map<String, dynamic>> _processOptions(List<Map<String, dynamic>> options) {
    final List<Map<String, dynamic>> variants = [];
    for (final option in options) {
      final optionName = option['option_name'] as String;
      final variantList = option['variants'] as List<dynamic>;
      for (final v in variantList) {
        variants.add({
          'option_name': optionName,
          'variant_name': v['name'],
          'price': (v['price'] as num).toInt(),
          'base_price': (v['base_price'] as num?)?.toInt() ?? 0,
          'unit': v['unit'],
        });
      }
    }
    return variants;
  }

  MenuItemModel _mapToModel(String id, Map<String, dynamic> data) {
    return MenuItemModel.fromJson({
      ...data,
      'id': id,
      'categories': {
        'id': data['category_id'],
        'name': data['category_name'],
      },
    });
  }
}
