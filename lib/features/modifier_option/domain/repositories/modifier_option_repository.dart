import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/modifier_option/domain/entities/modifier_option.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ModifierOptionRepository {
  Future<Either<Failure, List<ModifierOption>>> getAllModifierOptionsByMenuId(
    String menuId,
  );

  Future<Either<Failure, List<ModifierOption>>> getAllModifierOptions();

  Future<Either<Failure, Set<String>>> getSelectedModifierGroupIdsByMenuId(
    String menuId,
  );

  Future<Either<Failure, void>> updateMenuModifierGroupMappings({
    required String menuId,
    required Set<String> modifierGroupIds,
  });
}
