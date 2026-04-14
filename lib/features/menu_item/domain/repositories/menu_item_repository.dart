import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class MenuItemRepository {
  Future<Either<Failure, List<MenuItem>>> getAllMenuItems();
  Future<Either<Failure, List<MenuItem>>> getEnabledMenuItems();
  Future<Either<Failure, MenuItem>> createMenuItem({
    required String name,
    required int price,
    required int basePrice,
    required String categoryId,
    required String unit,
    required bool enabled,
    required List<Map<String, dynamic>> options,
  });
  Future<Either<Failure, MenuItem>> updateMenuItemAvailability({
    required String menuItemId,
    required bool enabled,
  });
  Future<Either<Failure, MenuItem>> updateMenuItem({
    required String id,
    required String name,
    required int price,
    required int basePrice,
    required String categoryId,
    required String unit,
    required bool enabled,
    required List<Map<String, dynamic>> options,
  });
}
