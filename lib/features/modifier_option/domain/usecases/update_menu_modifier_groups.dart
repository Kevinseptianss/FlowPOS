import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/modifier_option/domain/repositories/modifier_option_repository.dart';
import 'package:fpdart/fpdart.dart';

class UpdateMenuModifierGroups
    implements UseCase<void, UpdateMenuModifierGroupsParams> {
  final ModifierOptionRepository modifierOptionRepository;

  const UpdateMenuModifierGroups(this.modifierOptionRepository);

  @override
  Future<Either<Failure, void>> call(
    UpdateMenuModifierGroupsParams params,
  ) async {
    return await modifierOptionRepository.updateMenuModifierGroupMappings(
      menuId: params.menuId,
      modifierGroupIds: params.modifierGroupIds,
    );
  }
}

class UpdateMenuModifierGroupsParams {
  final String menuId;
  final Set<String> modifierGroupIds;

  const UpdateMenuModifierGroupsParams({
    required this.menuId,
    required this.modifierGroupIds,
  });
}
