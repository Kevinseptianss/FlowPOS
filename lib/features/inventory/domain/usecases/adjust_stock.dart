import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/inventory/domain/entities/stock.dart';
import 'package:flow_pos/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:fpdart/fpdart.dart';

class AdjustStock implements UseCase<Stock, AdjustStockParams> {
  final InventoryRepository repository;

  AdjustStock(this.repository);

  @override
  Future<Either<Failure, Stock>> call(AdjustStockParams params) async {
    return await repository.adjustStock(
      stockId: params.stockId,
      amount: params.amount,
      reason: params.reason,
      referenceId: params.referenceId,
    );
  }
}

class AdjustStockParams {
  final String stockId;
  final double amount;
  final String reason;
  final String? referenceId;

  AdjustStockParams({
    required this.stockId,
    required this.amount,
    required this.reason,
    this.referenceId,
  });
}
