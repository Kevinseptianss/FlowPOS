import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';
import 'package:flow_pos/features/menu_item/domain/repositories/menu_item_repository.dart';
import 'package:fpdart/fpdart.dart';

class UpdateMenuItemAvailability
    implements UseCase<MenuItem, UpdateMenuItemAvailabilityParams> {
  final MenuItemRepository menuItemRepository;

  const UpdateMenuItemAvailability(this.menuItemRepository);

  @override
  Future<Either<Failure, MenuItem>> call(
    UpdateMenuItemAvailabilityParams params,
  ) async {
    if (params.menuItemId.trim().isEmpty) {
      return left(const Failure('Menu item id is required.'));
    }

    return await menuItemRepository.updateMenuItemAvailability(
      menuItemId: params.menuItemId,
      enabled: params.enabled,
    );
  }
}

class UpdateMenuItemAvailabilityParams {
  final String menuItemId;
  final bool enabled;

  const UpdateMenuItemAvailabilityParams({
    required this.menuItemId,
    required this.enabled,
  });
}
