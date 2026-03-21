import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';
import 'package:flow_pos/features/menu_item/domain/repositories/menu_item_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetAllMenuItems implements UseCase<List<MenuItem>, NoParams> {
  final MenuItemRepository menuItemRepository;

  const GetAllMenuItems(this.menuItemRepository);

  @override
  Future<Either<Failure, List<MenuItem>>> call(NoParams params) async {
    return await menuItemRepository.getAllMenuItems();
  }
}
