import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/modifier_option/data/datasources/modifier_option_remote_data_source.dart';
import 'package:flow_pos/features/modifier_option/domain/entities/modifier_option.dart';
import 'package:flow_pos/features/modifier_option/domain/repositories/modifier_option_repository.dart';
import 'package:fpdart/fpdart.dart';

class ModifierOptionRepositoryImpl implements ModifierOptionRepository {
  final ModifierOptionRemoteDataSource modifierOptionRemoteDataSource;

  ModifierOptionRepositoryImpl(this.modifierOptionRemoteDataSource);

  @override
  Future<Either<Failure, List<ModifierOption>>> getAllModifierOptionsByMenuId(
    String menuId,
  ) async {
    try {
      final modifierOptions = await modifierOptionRemoteDataSource
          .getAllModifierOptionsByMenuId(menuId);
      return right(modifierOptions);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
