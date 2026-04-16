import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flow_pos/core/error/server_exception.dart';

abstract interface class InventoryRemoteDataSource {
  Future<List<Map<String, dynamic>>> getStockLevels();
  
  Future<Map<String, dynamic>> adjustStock({
    required String stockId,
    required double amount,
    required String reason,
    String? referenceId,
  });

  Future<Map<String, dynamic>> createPurchaseOrder({
    required String supplierName,
    required List<Map<String, dynamic>> items,
  });

  Future<List<Map<String, dynamic>>> getPurchaseOrders();
  
  Future<List<Map<String, dynamic>>> getStockHistory(String stockId);

  Future<Map<String, dynamic>> getPurchaseOrderById(String poId);
}

class InventoryRemoteDataSourceImpl implements InventoryRemoteDataSource {
  final FirebaseFirestore _firestore;

  InventoryRemoteDataSourceImpl(this._firestore);

  @override
  Future<List<Map<String, dynamic>>> getStockLevels() async {
    try {
      final stockSnapshot = await _firestore
          .collection('stocks')
          .orderBy('updated_at', descending: true)
          .get();
      
      final stocks = stockSnapshot.docs.map((doc) {
        final data = Map<String, dynamic>.from(doc.data());
        data['id'] = doc.id;
        return data;
      }).toList();

      final menuSnapshot = await _firestore.collection('menu_items').get();
      final List<Map<String, dynamic>> finalStocks = List.from(stocks);
      bool modified = false;

      final Map<String, Map<String, dynamic>> menuMap = {
        for (var doc in menuSnapshot.docs) doc.id: Map<String, dynamic>.from(doc.data())
      };

      // 1. Repair existing stocks that are missing metadata
      for (var s in finalStocks) {
        final mId = s['menu_item_id']?.toString();
        final vId = s['variant_id']?.toString();
        if (mId == null) continue;

        final mData = menuMap[mId];
        if (mData == null) continue;

        bool needsUpdate = false;
        if (s['menu_items'] == null) {
          s['menu_items'] = {
            'name': mData['name'] ?? 'Unknown',
            'category_id': mData['category_id'],
            'price': mData['price'] ?? 0,
            'base_price': mData['base_price'] ?? 0,
          };
          needsUpdate = true;
        }

        if (vId != null && s['menu_item_variants'] == null) {
          final mVariants = (mData['menu_item_variants'] ?? mData['variants']) as List? ?? [];
          final variant = mVariants.firstWhere(
            (v) => v != null && v['id']?.toString() == vId, 
            orElse: () => null
          );
          if (variant != null) {
            s['menu_item_variants'] = variant;
            needsUpdate = true;
          }
        }

        if (needsUpdate) {
          // Use .set with merge: true for safety
          await _firestore.collection('stocks').doc(s['id'].toString()).set({
            'menu_items': s['menu_items'],
            if (s['menu_item_variants'] != null) 'menu_item_variants': s['menu_item_variants'],
            'updated_at': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          modified = true;
        }
      }

      // 2. Add missing stocks for new products/variants
      for (var entry in menuMap.entries) {
        final menuId = entry.key;
        final menuData = entry.value;
        final variantsRaw = (menuData['menu_item_variants'] ?? menuData['variants']) as List? ?? [];
        
        final List<Map<String, dynamic>> variants = [];
        for (var i = 0; i < variantsRaw.length; i++) {
          if (variantsRaw[i] == null) continue;
          final v = Map<String, dynamic>.from(variantsRaw[i]);
          if (v['id'] == null) {
            v['id'] = 'v_${menuId}_${v['variant_name'] ?? v['name'] ?? i}';
          }
          variants.add(v);
        }

        if (variants.isEmpty) {
          final hasStock = finalStocks.any((s) => 
            s['menu_item_id']?.toString() == menuId.toString() && 
            (s['variant_id'] == null || s['variant_id'] == '')
          );
          
          if (!hasStock) {
            final newStockRef = _firestore.collection('stocks').doc();
            final newStock = {
              'menu_item_id': menuId,
              'variant_id': null,
              'quantity': 0,
              'min_threshold': 5,
              'updated_at': FieldValue.serverTimestamp(),
              'menu_items': {
                'name': menuData['name'] ?? 'Unknown',
                'category_id': menuData['category_id'],
                'price': menuData['price'] ?? 0,
                'base_price': menuData['base_price'] ?? 0,
              }
            };
            await newStockRef.set(newStock);
            finalStocks.add(newStock..['id'] = newStockRef.id);
            modified = true;
          }
        } else {
          for (var v in variants) {
            final vId = v['id']?.toString();
            if (vId == null) continue;
            
            final hasStock = finalStocks.any((s) => s['variant_id']?.toString() == vId);
            
            if (!hasStock) {
              final newStockRef = _firestore.collection('stocks').doc();
              final newStock = {
                'menu_item_id': menuId,
                'variant_id': vId,
                'quantity': 0,
                'min_threshold': 5,
                'updated_at': FieldValue.serverTimestamp(),
                'menu_items': {
                  'name': menuData['name'] ?? 'Unknown',
                  'category_id': menuData['category_id'],
                  'price': menuData['price'] ?? 0,
                  'base_price': menuData['base_price'] ?? 0,
                },
                'menu_item_variants': v,
              };
              await newStockRef.set(newStock);
              finalStocks.add(newStock..['id'] = newStockRef.id);
              modified = true;
            }
          }
        }
      }

      if (modified) {
        finalStocks.sort((a, b) {
          final aTime = a['updated_at'];
          final bTime = b['updated_at'];
          if (aTime is! Timestamp || bTime is! Timestamp) return 0;
          return bTime.compareTo(aTime);
        });
      }

      return finalStocks;
    } catch (e, stack) {
      print('--- [INVENTORY ERROR] getStockLevels ---');
      print(e);
      print(stack);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> adjustStock({
    required String stockId,
    required double amount,
    required String reason,
    String? referenceId,
  }) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final stockRef = _firestore.collection('stocks').doc(stockId);
        final stockDoc = await transaction.get(stockRef);

        if (!stockDoc.exists) throw const ServerException('Stock not found');

        final data = Map<String, dynamic>.from(stockDoc.data()!);
        final double currentQty = (data['quantity'] as num?)?.toDouble() ?? 0;
        final double newQty = currentQty + amount;

        transaction.update(stockRef, {
          'quantity': newQty,
          'updated_at': FieldValue.serverTimestamp(),
        });

        final logRef = _firestore.collection('stock_transactions').doc();
        transaction.set(logRef, {
          'id': logRef.id,
          'stock_id': stockId,
          'type': amount > 0 ? 'IN' : 'OUT',
          'reason': reason,
          'amount': amount.abs(),
          'reference_id': referenceId,
          'created_at': FieldValue.serverTimestamp(),
        });

        // DO NOT READ AFTER WRITE. Construct the return data locally.
        data['id'] = stockId;
        data['quantity'] = newQty;
        return data;
      });
    } catch (e, stack) {
      print('--- [INVENTORY ERROR] adjustStock ---');
      print(e);
      print(stack);
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> createPurchaseOrder({
    required String supplierName,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final batch = _firestore.batch();
      final poRef = _firestore.collection('purchase_orders').doc();
      final poId = poRef.id;

      int totalAmount = 0;
      for (var item in items) {
        totalAmount += ((item['quantity'] as num) * (item['price_per_unit'] as num)).toInt();
      }

      // Filter out the 'name' from each item before saving to database
      final dbItems = items.map((i) => {
        'stock_id': i['stock_id'],
        'quantity': i['quantity'],
        'price_per_unit': i['price_per_unit'],
      }).toList();

      final poData = {
        'id': poId,
        'supplier_name': supplierName,
        'total_amount': totalAmount,
        'status': 'RECEIVED',
        'items': dbItems,
        'created_at': FieldValue.serverTimestamp(),
      };

      batch.set(poRef, poData);

      // We need to update stocks too. Since batches can't read, we have to do it carefully or use transactions.
      // For simplicity in this migration, I'll use a transaction for the whole operation if consistency is key.
      // But multiple stocks update in one transaction might hit limits.
      // Actually, let's use a simpler approach for the PO creation to match the original "loop and update" logic but using Firestore.
      
      await _firestore.collection('purchase_orders').doc(poId).set(poData);

      for (var item in items) {
        final stockId = item['stock_id'] as String;
        final qty = (item['quantity'] as num).toDouble();
        final pricePerUnit = (item['price_per_unit'] as num).toInt();

        await adjustStock(
          stockId: stockId,
          amount: qty,
          reason: 'PURCHASE',
          referenceId: poId,
        );

        // Sync price back to MenuItem/Variant
        final stockDoc = await _firestore.collection('stocks').doc(stockId).get();
        final data = stockDoc.data();
        if (data != null) {
          final String? menuItemId = data['menu_item_id'];
          final String? variantId = data['variant_id'];

          if (variantId != null && menuItemId != null) {
            // Update the variant inside menu_items doc
            final menuRef = _firestore.collection('menu_items').doc(menuItemId);
            final menuSnapshot = await menuRef.get();
            if (menuSnapshot.exists) {
              List variants = List.from(menuSnapshot.data()?['menu_item_variants'] ?? menuSnapshot.data()?['variants'] ?? []);
              for (var i = 0; i < variants.length; i++) {
                if (variants[i]['id'] == variantId) {
                  variants[i]['base_price'] = pricePerUnit;
                  break;
                }
              }
              await menuRef.update({'menu_item_variants': variants});
            }
          } else if (menuItemId != null) {
            await _firestore.collection('menu_items').doc(menuItemId).update({'base_price': pricePerUnit});
          }
        }
      }

      return poData;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getPurchaseOrders() async {
    try {
      final snapshot = await _firestore
          .collection('purchase_orders')
          .orderBy('created_at', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getStockHistory(String stockId) async {
    try {
      final snapshot = await _firestore
          .collection('stock_transactions')
          .where('stock_id', isEqualTo: stockId)
          .orderBy('created_at', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>> getPurchaseOrderById(String poId) async {
    try {
      final doc = await _firestore.collection('purchase_orders').doc(poId).get();
      if (!doc.exists) throw const ServerException('PO not found');
      
      final data = doc.data()!;
      final items = (data['items'] as List? ?? [])
          .map((i) => Map<String, dynamic>.from(i))
          .toList();
      
      // We need to hydrate the item names because we don't store snapshots
      for (var i = 0; i < items.length; i++) {
        final stockId = items[i]['stock_id'];
        if (stockId != null) {
          final stockDoc = await _firestore.collection('stocks').doc(stockId).get();
          if (stockDoc.exists) {
            final stockData = Map<String, dynamic>.from(stockDoc.data()!);
            stockData['id'] = stockDoc.id;
            items[i]['stocks'] = stockData; // Place it where the repo expects it
          }
        }
      }
      
      data['purchase_order_items'] = items; // Replicate the return structure expected by repo
      return data;
    } catch (e, stack) {
      print('--- [INVENTORY ERROR] getPurchaseOrderById ---');
      print(e);
      print(stack);
      throw ServerException(e.toString());
    }
  }
}
