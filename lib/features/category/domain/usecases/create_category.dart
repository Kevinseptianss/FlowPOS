import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/category/domain/entities/category.dart';
import 'package:flow_pos/features/category/domain/repositories/category_repository.dart';
import 'package:fpdart/fpdart.dart';

class CreateCategory implements UseCase<Category, CreateCategoryParams> {
  final CategoryRepository categoryRepository;

  const CreateCategory(this.categoryRepository);

  @override
  Future<Either<Failure, Category>> call(CreateCategoryParams params) async {
    final trimmedName = params.name.trim();

    if (trimmedName.isEmpty) {
      return left(const Failure('Category name cannot be empty.'));
    }

    return await categoryRepository.createCategory(trimmedName);
  }
}

class CreateCategoryParams {
  final String name;

  const CreateCategoryParams({required this.name});
}
