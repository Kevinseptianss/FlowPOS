import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class MenuItemRepository {
  Future<Either<Failure, List<MenuItem>>> getAllMenuItems();
}
