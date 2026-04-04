import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/category/data/datasources/category_remote_data_source.dart';
import 'package:flow_pos/features/category/data/models/category_model.dart';
import 'package:flow_pos/features/category/domain/entities/category.dart';
import 'package:flow_pos/features/category/domain/repositories/category_repository.dart';
import 'package:fpdart/fpdart.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryRemoteDataSource categoryRemoteDataSource;

  CategoryRepositoryImpl(this.categoryRemoteDataSource);

  @override
  Future<Either<Failure, List<Category>>> getAllCategories() async {
    try {
      final categories = await categoryRemoteDataSource.getAllCategories();
      // Add "All" category at the beginning of the list
      categories.insert(0, const CategoryModel(id: 'all', name: 'All'));
      return right(categories);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, Category>> createCategory(String name) async {
    try {
      final category = await categoryRemoteDataSource.createCategory(name);
      return right(category);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
