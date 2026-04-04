import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/category/domain/entities/category.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class CategoryRepository {
  Future<Either<Failure, List<Category>>> getAllCategories();
  Future<Either<Failure, Category>> createCategory(String name);
}
