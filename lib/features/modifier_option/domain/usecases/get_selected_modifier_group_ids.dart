import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/modifier_option/domain/repositories/modifier_option_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetSelectedModifierGroupIds
    implements UseCase<Set<String>, GetSelectedModifierGroupIdsParams> {
  final ModifierOptionRepository modifierOptionRepository;

  const GetSelectedModifierGroupIds(this.modifierOptionRepository);

  @override
  Future<Either<Failure, Set<String>>> call(
    GetSelectedModifierGroupIdsParams params,
  ) async {
    return await modifierOptionRepository.getSelectedModifierGroupIdsByMenuId(
      params.menuId,
    );
  }
}

class GetSelectedModifierGroupIdsParams {
  final String menuId;

  const GetSelectedModifierGroupIdsParams({required this.menuId});
}
