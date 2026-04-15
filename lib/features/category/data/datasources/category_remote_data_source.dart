import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/category/data/models/category_model.dart';

abstract interface class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getAllCategories();
  Future<CategoryModel> createCategory(String name);
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final FirebaseFirestore _firestore;

  CategoryRemoteDataSourceImpl(this._firestore);

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final snapshot = await _firestore
          .collection('categories')
          .orderBy('name', descending: false)
          .get();

      return snapshot.docs
          .map((doc) => CategoryModel.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<CategoryModel> createCategory(String name) async {
    try {
      final docRef = _firestore.collection('categories').doc();
      final data = {
        'id': docRef.id,
        'name': name,
        'created_at': FieldValue.serverTimestamp(),
      };
      
      await docRef.set(data);

      return CategoryModel.fromJson(data);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
