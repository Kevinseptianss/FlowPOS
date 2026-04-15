import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/modifier_option/data/models/modifier_option_model.dart';
import 'package:flow_pos/features/modifier_option/domain/entities/create_modifier_option_input.dart';

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

class ModifierOptionRemoteDataSourceImpl implements ModifierOptionRemoteDataSource {
  final FirebaseFirestore _firestore;

  ModifierOptionRemoteDataSourceImpl(this._firestore);

  @override
  Future<List<ModifierOptionModel>> getAllModifierOptionsByMenuId(
    String menuId,
  ) async {
    try {
      final menuDoc = await _firestore.collection('menu_items').doc(menuId).get();
      if (!menuDoc.exists) return [];

      final List<String> groupIds = List<String>.from(menuDoc.data()?['modifier_group_ids'] ?? []);
      if (groupIds.isEmpty) return [];

      final result = <ModifierOptionModel>[];
      
      // Firestore 'in' query limited to 30 items
      final groupSnapshots = await _firestore
          .collection('modifier_groups')
          .where(FieldPath.documentId, whereIn: groupIds)
          .get();

      for (final doc in groupSnapshots.docs) {
        final data = doc.data();
        final groupId = doc.id;
        final groupName = data['name'] ?? '';
        final options = List<Map<String, dynamic>>.from(data['options'] ?? []);

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
      final snapshot = await _firestore
          .collection('modifier_groups')
          .orderBy('name', descending: false)
          .get();

      final result = <ModifierOptionModel>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final groupId = doc.id;
        final groupName = data['name'] ?? '';
        final options = List<Map<String, dynamic>>.from(data['options'] ?? []);

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
    try {
      final docRef = _firestore.collection('modifier_groups').doc();
      final optionsData = options.map((opt) => {
        'id': _firestore.collection('placeholder').doc().id, // Generate pseudo-id for option
        'name': opt.name,
        'additional_price': opt.additionalPrice,
      }).toList();

      await docRef.set({
        'id': docRef.id,
        'name': groupName,
        'options': optionsData,
        'created_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Set<String>> getSelectedModifierGroupIdsByMenuId(String menuId) async {
    try {
      final doc = await _firestore.collection('menu_items').doc(menuId).get();
      if (doc.exists) {
        return Set<String>.from(doc.data()?['modifier_group_ids'] ?? []);
      }
      return {};
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
      await _firestore.collection('menu_items').doc(menuId).update({
        'modifier_group_ids': modifierGroupIds.toList(),
      });
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
