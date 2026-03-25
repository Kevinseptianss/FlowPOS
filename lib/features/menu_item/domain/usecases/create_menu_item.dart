import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';
import 'package:flow_pos/features/menu_item/domain/repositories/menu_item_repository.dart';
import 'package:fpdart/fpdart.dart';

class CreateMenuItem implements UseCase<MenuItem, CreateMenuItemParams> {
  final MenuItemRepository menuItemRepository;

  const CreateMenuItem(this.menuItemRepository);

  @override
  Future<Either<Failure, MenuItem>> call(CreateMenuItemParams params) async {
    final trimmedName = params.name.trim();

    if (trimmedName.isEmpty) {
      return left(const Failure('Menu name cannot be empty.'));
    }

    if (params.price <= 0) {
      return left(const Failure('Price must be greater than 0.'));
    }

    if (params.categoryId.trim().isEmpty) {
      return left(const Failure('Category is required.'));
    }

    return await menuItemRepository.createMenuItem(
      name: trimmedName,
      price: params.price,
      categoryId: params.categoryId,
    );
  }
}

class CreateMenuItemParams {
  final String name;
  final int price;
  final String categoryId;

  const CreateMenuItemParams({
    required this.name,
    required this.price,
    required this.categoryId,
  });
}
