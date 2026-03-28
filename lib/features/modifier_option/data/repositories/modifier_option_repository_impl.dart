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

  @override
  Future<Either<Failure, List<ModifierOption>>> getAllModifierOptions() async {
    try {
      final modifierOptions = await modifierOptionRemoteDataSource
          .getAllModifierOptions();
      return right(modifierOptions);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, Set<String>>> getSelectedModifierGroupIdsByMenuId(
    String menuId,
  ) async {
    try {
      final selectedGroupIds = await modifierOptionRemoteDataSource
          .getSelectedModifierGroupIdsByMenuId(menuId);
      return right(selectedGroupIds);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> updateMenuModifierGroupMappings({
    required String menuId,
    required Set<String> modifierGroupIds,
  }) async {
    try {
      await modifierOptionRemoteDataSource.updateMenuModifierGroupMappings(
        menuId: menuId,
        modifierGroupIds: modifierGroupIds,
      );
      return right(null);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
