import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/menu_item/data/datasources/menu_item_remote_data_source.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';
import 'package:flow_pos/features/menu_item/domain/repositories/menu_item_repository.dart';
import 'package:fpdart/fpdart.dart';

class MenuItemRepositoryImpl implements MenuItemRepository {
  final MenuItemRemoteDataSource menuItemRemoteDataSource;

  MenuItemRepositoryImpl(this.menuItemRemoteDataSource);

  @override
  Future<Either<Failure, List<MenuItem>>> getAllMenuItems() async {
    try {
      final menuItems = await menuItemRemoteDataSource.getAllMenuItems();
      return right(menuItems);
    } on ServerException catch (e) {
      return left(Failure(e.message));
    }
  }
}
