import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flow_pos/core/error/failure.dart';
import 'package:flow_pos/features/inventory/data/datasources/inventory_remote_data_source.dart';
import 'package:flow_pos/features/inventory/domain/entities/purchase_order.dart';
import 'package:flow_pos/features/inventory/domain/entities/stock.dart';
import 'package:flow_pos/features/inventory/domain/entities/stock_transaction.dart';
import 'package:flow_pos/features/inventory/domain/repositories/inventory_repository.dart';
import 'package:fpdart/fpdart.dart';

class InventoryRepositoryImpl implements InventoryRepository {
  final InventoryRemoteDataSource remoteDataSource;

  InventoryRepositoryImpl(this.remoteDataSource);

  DateTime _parseDate(dynamic date) {
    if (date == null) return DateTime.now();
    if (date is Timestamp) return date.toDate();
    if (date is String) return DateTime.parse(date);
    return DateTime.now();
  }

  @override
  Future<Either<Failure, List<Stock>>> getStockLevels() async {
    try {
      final res = await remoteDataSource.getStockLevels();
      final List<Stock> stocks = [];
      for (var json in res) {
        final poItems = json['purchase_order_items'] as List?;
        final double quantity = (json['quantity'] ?? 0 as num).toDouble();
        final bool hasPO = (poItems != null && poItems.isNotEmpty);

        String itemName = 'Unknown Product';
        String? catId;
        int? sellingPrice;
        int? costPrice;

        // Try to get base info from menu_items snapshot in stock doc
        final productInfo = json['menu_items'];
        if (productInfo != null) {
          itemName = productInfo['name']?.toString() ?? itemName;
          catId = productInfo['category_id']?.toString();
          sellingPrice = (productInfo['price'] as num?)?.toInt();
          costPrice = (productInfo['base_price'] as num?)?.toInt();
        }

        // Check for variant details
        final variantInfo = json['menu_item_variants'];
        if (variantInfo != null) {
          final String? optionName = variantInfo['option_name']?.toString();
          final String? variantName = (variantInfo['variant_name'] ?? variantInfo['name'])?.toString();
          
          if (variantInfo['base_price'] != null) {
            costPrice = (variantInfo['base_price'] as num).toInt();
          }
          if (variantInfo['price'] != null) {
            sellingPrice = (variantInfo['price'] as num).toInt();
          }
          
          if (optionName != null && variantName != null) {
            itemName = '$itemName - $optionName - $variantName';
          } else if (variantName != null) {
            itemName = '$itemName - $variantName';
          }
        }
        
        final String sId = json['id']?.toString() ?? '';
        final String mId = json['menu_item_id']?.toString() ?? '';
        final String? vId = json['variant_id']?.toString();
        
        stocks.add(Stock(
          id: sId,
          menuItemId: mId,
          variantId: vId,
          quantity: quantity,
          minThreshold: (json['min_threshold'] ?? 5 as num).toInt(),
          updatedAt: _parseDate(json['updated_at']),
          hasPurchaseOrder: hasPO,
          itemName: itemName,
          variantName: variantInfo != null 
              ? (variantInfo['variant_name'] ?? variantInfo['option_name'] ?? variantInfo['name']) 
              : null,
          categoryId: catId,
          price: sellingPrice,
          basePrice: costPrice,
        ));
      }
      return right(stocks);
    } catch (e) {
      return left(Failure('Gagal memuat stok: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Stock>> adjustStock({
    required String stockId,
    required double amount,
    required String reason,
    String? referenceId,
  }) async {
    try {
      final json = await remoteDataSource.adjustStock(
        stockId: stockId,
        amount: amount,
        reason: reason,
        referenceId: referenceId,
      );
      
      String itemName = 'Unknown';
      String? catId;
      if (json['menu_items'] != null) {
        itemName = json['menu_items']['name'] ?? 'Unknown';
        catId = json['menu_items']['category_id'];
      } else if (json['menu_item_variants'] != null && json['menu_item_variants']['menu_items'] != null) {
        itemName = json['menu_item_variants']['menu_items']['name'] ?? 'Unknown';
        catId = json['menu_item_variants']['menu_items']['category_id'];
      }

      if (json['menu_item_variants'] != null) {
        final option = json['menu_item_variants']['option_name'];
        final variant = json['menu_item_variants']['variant_name'];
        if (option != null && variant != null) {
          itemName = '$itemName - $option - $variant';
        } else if (variant != null) {
          itemName = '$itemName - $variant';
        }
      } else if (itemName == 'Unknown' && json['menu_item_variants'] != null) {
        itemName = json['menu_item_variants']['variant_name'] ?? json['menu_item_variants']['option_name'] ?? 'Unknown';
      }

      return right(Stock(
        id: json['id'],
        menuItemId: json['menu_item_id'],
        variantId: json['variant_id'],
        quantity: (json['quantity'] ?? 0 as num).toDouble(),
        minThreshold: (json['min_threshold'] ?? 5 as num).toInt(),
        updatedAt: _parseDate(json['updated_at']),
        hasPurchaseOrder: true,
        itemName: itemName,
        categoryId: catId,
      ));
    } catch (e) {
      return left(Failure('Gagal menyesuaikan stok: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> createPurchaseOrder({
    required String supplierName,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final json = await remoteDataSource.createPurchaseOrder(
        supplierName: supplierName,
        items: items,
      );
      
      return right(PurchaseOrder(
        id: json['id'],
        supplierName: json['supplier_name'],
        totalAmount: json['total_amount'],
        status: json['status'],
        createdAt: _parseDate(json['created_at']),
        items: (json['purchase_order_items'] as List? ?? []).map((i) => PurchaseOrderItem(
          id: i['id'],
          stockId: i['stock_id'],
          itemName: 'Item', // Name not easily available here without extra fetch
          quantity: (i['quantity'] as num).toDouble(),
          pricePerUnit: i['price_per_unit'],
        )).toList(),
      ));
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PurchaseOrder>>> getPurchaseOrders() async {
    try {
      final res = await remoteDataSource.getPurchaseOrders();
      return right(res.map((json) => PurchaseOrder(
        id: json['id'],
        supplierName: json['supplier_name'],
        totalAmount: json['total_amount'],
        status: json['status'],
        createdAt: _parseDate(json['created_at']),
      )).toList());
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, PurchaseOrder>> getPurchaseOrder(String poId) async {
    try {
      final json = await remoteDataSource.getPurchaseOrderById(poId);
      
      return right(PurchaseOrder(
        id: json['id'],
        supplierName: json['supplier_name'],
        totalAmount: json['total_amount'],
        status: json['status'],
        createdAt: _parseDate(json['created_at']),
        items: (json['purchase_order_items'] as List? ?? []).map((i) {
          String itName = 'Unknown Item';
          final stocks = i['stocks'];
          if (stocks != null) {
            final menuItems = stocks['menu_items'];
            final variants = stocks['menu_item_variants'];
            if (menuItems != null) {
              itName = menuItems['name'] ?? itName;
            }
            if (variants != null) {
              final opt = variants['option_name'];
              final vnt = variants['variant_name'];
              if (opt != null && vnt != null) {
                itName = '$itName - $opt - $vnt';
              } else if (vnt != null) {
                itName = '$itName - $vnt';
              }
            }
          }

          return PurchaseOrderItem(
            id: i['id'],
            stockId: i['stock_id'],
            itemName: itName,
            quantity: (i['quantity'] as num).toDouble(),
            pricePerUnit: i['price_per_unit'],
          );
        }).toList(),
      ));
    } catch (e) {
      return left(Failure('Gagal memuat detail PO: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<StockTransaction>>> getStockHistory(String stockId) async {
    try {
      final res = await remoteDataSource.getStockHistory(stockId);
      return right(res.map((json) => StockTransaction(
        id: json['id'],
        stockId: json['stock_id'],
        type: json['type'],
        reason: json['reason'],
        amount: (json['amount'] as num).toDouble(),
        referenceId: json['reference_id'],
        createdAt: _parseDate(json['created_at']),
      )).toList());
    } catch (e) {
      return left(Failure(e.toString()));
    }
  }
}

