import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/modifier_option/domain/entities/create_modifier_option_input.dart';
import 'package:flow_pos/features/modifier_option/domain/repositories/modifier_option_repository.dart';
import 'package:fpdart/fpdart.dart';

class CreateModifierGroupWithOptions
    implements UseCase<void, CreateModifierGroupWithOptionsParams> {
  final ModifierOptionRepository modifierOptionRepository;

  const CreateModifierGroupWithOptions(this.modifierOptionRepository);

  @override
  Future<Either<Failure, void>> call(
    CreateModifierGroupWithOptionsParams params,
  ) async {
    return await modifierOptionRepository.createModifierGroupWithOptions(
      groupName: params.groupName,
      options: params.options,
    );
  }
}

class CreateModifierGroupWithOptionsParams {
  final String groupName;
  final List<CreateModifierOptionInput> options;

  const CreateModifierGroupWithOptionsParams({
    required this.groupName,
    required this.options,
  });
}
