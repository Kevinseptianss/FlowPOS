import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/category/data/models/category_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract interface class CategoryRemoteDataSource {
  Future<List<CategoryModel>> getAllCategories();
}

class CategoryRemoteDataSourceImpl implements CategoryRemoteDataSource {
  final SupabaseClient supabaseClient;

  CategoryRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<CategoryModel>> getAllCategories() async {
    try {
      final response = await supabaseClient
          .from('categories')
          .select()
          .order('name', ascending: true);

      return response
          .map((category) => CategoryModel.fromJson(category))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
