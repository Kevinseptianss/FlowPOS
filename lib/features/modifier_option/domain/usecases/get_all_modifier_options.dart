import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/modifier_option/domain/entities/modifier_option.dart';
import 'package:flow_pos/features/modifier_option/domain/repositories/modifier_option_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetAllModifierOptions
    implements UseCase<List<ModifierOption>, GetAllModifierOptionsParams> {
  final ModifierOptionRepository modifierOptionRepository;

  const GetAllModifierOptions(this.modifierOptionRepository);

  @override
  Future<Either<Failure, List<ModifierOption>>> call(
    GetAllModifierOptionsParams params,
  ) async {
    return await modifierOptionRepository.getAllModifierOptionsByMenuId(
      params.menuId,
    );
  }
}

class GetAllModifierOptionsParams {
  final String menuId;

  const GetAllModifierOptionsParams({required this.menuId});
}
