import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/modifier_option/domain/entities/modifier_option.dart';
import 'package:flow_pos/features/modifier_option/domain/repositories/modifier_option_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetAllModifierGroupOptions
    implements UseCase<List<ModifierOption>, NoParams> {
  final ModifierOptionRepository modifierOptionRepository;

  const GetAllModifierGroupOptions(this.modifierOptionRepository);

  @override
  Future<Either<Failure, List<ModifierOption>>> call(NoParams params) async {
    return await modifierOptionRepository.getAllModifierOptions();
  }
}
