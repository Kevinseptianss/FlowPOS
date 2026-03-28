import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/modifier_option/domain/entities/create_modifier_option_input.dart';
import 'package:flow_pos/features/modifier_option/domain/entities/modifier_option.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ModifierOptionRepository {
  Future<Either<Failure, List<ModifierOption>>> getAllModifierOptionsByMenuId(
    String menuId,
  );

  Future<Either<Failure, List<ModifierOption>>> getAllModifierOptions();

  Future<Either<Failure, void>> createModifierGroupWithOptions({
    required String groupName,
    required List<CreateModifierOptionInput> options,
  });

  Future<Either<Failure, Set<String>>> getSelectedModifierGroupIdsByMenuId(
    String menuId,
  );

  Future<Either<Failure, void>> updateMenuModifierGroupMappings({
    required String menuId,
    required Set<String> modifierGroupIds,
  });
}
