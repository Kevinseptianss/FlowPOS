import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/inventory/domain/entities/purchase_order.dart';
import 'package:flow_pos/features/inventory/domain/entities/stock.dart';
import 'package:flow_pos/features/inventory/domain/entities/stock_transaction.dart';
import 'package:fpdart/fpdart.dart';

abstract interface class InventoryRepository {
  Future<Either<Failure, List<Stock>>> getStockLevels();
  
  Future<Either<Failure, Stock>> adjustStock({
    required String stockId,
    required double amount,
    required String reason,
    String? referenceId,
  });

  Future<Either<Failure, PurchaseOrder>> createPurchaseOrder({
    required String supplierName,
    required List<Map<String, dynamic>> items,
  });

  Future<Either<Failure, List<PurchaseOrder>>> getPurchaseOrders();
  
  Future<Either<Failure, PurchaseOrder>> getPurchaseOrder(String poId);
  
  Future<Either<Failure, List<StockTransaction>>> getStockHistory(String stockId);
}
