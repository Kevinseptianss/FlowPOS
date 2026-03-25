import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class MenuItemRepository {
  Future<Either<Failure, List<MenuItem>>> getAllMenuItems();
  Stream<Either<Failure, List<MenuItem>>> listenAllMenuItems();
  Future<Either<Failure, MenuItem>> createMenuItem({
    required String name,
    required int price,
    required String categoryId,
  });
}
