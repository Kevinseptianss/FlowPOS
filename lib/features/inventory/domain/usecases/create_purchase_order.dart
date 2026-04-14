import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/core/usecase/use_case.dart';
import 'package:flow_pos/features/inventory/domain/entities/purchase_order.dart';
import 'package:flow_pos/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:fpdart/fpdart.dart';

class CreatePurchaseOrder implements UseCase<PurchaseOrder, CreatePurchaseOrderParams> {
  final InventoryRepository repository;

  CreatePurchaseOrder(this.repository);

  @override
  Future<Either<Failure, PurchaseOrder>> call(CreatePurchaseOrderParams params) async {
    return await repository.createPurchaseOrder(
      supplierName: params.supplierName,
      items: params.items,
    );
  }
}

class CreatePurchaseOrderParams {
  final String supplierName;
  final List<Map<String, dynamic>> items;

  CreatePurchaseOrderParams({
    required this.supplierName,
    required this.items,
  });
}
