import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/modifier_option/domain/entities/modifier_option.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class ModifierOptionRepository {
  Future<Either<Failure, List<ModifierOption>>> getAllModifierOptionsByMenuId(
    String menuId,
  );
}
