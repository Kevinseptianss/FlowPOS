import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/inventory/domain/entities/stock.dart';
import 'package:flow_pos/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetStockLevels implements UseCase<List<Stock>, NoParams> {
  final InventoryRepository repository;

  GetStockLevels(this.repository);

  @override
  Future<Either<Failure, List<Stock>>> call(NoParams params) async {
    return await repository.getStockLevels();
  }
}
