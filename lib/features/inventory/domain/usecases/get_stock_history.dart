import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/inventory/domain/entities/stock_transaction.dart';
import 'package:flow_pos/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:fpdart/fpdart.dart';

class GetStockHistory implements UseCase<List<StockTransaction>, String> {
  final InventoryRepository repository;

  GetStockHistory(this.repository);

  @override
  Future<Either<Failure, List<StockTransaction>>> call(String params) async {
    return await repository.getStockHistory(params);
  }
}
