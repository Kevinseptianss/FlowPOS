import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/category/domain/entities/category.dart';
import 'package:flow_pos/features/category/domain/repositories/category_repository.dart';
import 'package:fpdart/fpdart.dart';

class ListenAllCategories {
  final CategoryRepository categoryRepository;

  const ListenAllCategories(this.categoryRepository);

  Stream<Either<Failure, List<Category>>> call() {
    return categoryRepository.listenAllCategories();
  }
}
