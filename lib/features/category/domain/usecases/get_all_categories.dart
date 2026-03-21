import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/category/domain/entities/category.dart';
import 'package:flow_pos/features/category/domain/repositories/category_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetAllCategories implements UseCase<List<Category>, NoParams> {
  final CategoryRepository categoryRepository;

  const GetAllCategories(this.categoryRepository);

  @override
  Future<Either<Failure, List<Category>>> call(NoParams params) async {
    return await categoryRepository.getAllCategories();
  }
}
