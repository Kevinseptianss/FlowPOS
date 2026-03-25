import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';
import 'package:flow_pos/features/menu_item/domain/repositories/menu_item_repository.dart';
import 'package:fpdart/fpdart.dart';

class ListenAllMenuItems {
  final MenuItemRepository menuItemRepository;

  const ListenAllMenuItems(this.menuItemRepository);

  Stream<Either<Failure, List<MenuItem>>> call() {
    return menuItemRepository.listenAllMenuItems();
  }
}
