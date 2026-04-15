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
      final snapshot = await _firestore
          .collection('stocks')
          .orderBy('updated_at', descending: true)
          .get();
      
      return snapshot.docs.map((doc) => doc.data()..['id'] = doc.id).toList();
    } catch (e) {
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

        final double currentQty = (stockDoc.data()?['quantity'] as num?)?.toDouble() ?? 0;
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

        final updatedData = (await transaction.get(stockRef)).data()!;
        return updatedData..['id'] = stockId;
      });
    } catch (e) {
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

      final poData = {
        'id': poId,
        'supplier_name': supplierName,
        'total_amount': totalAmount,
        'status': 'RECEIVED',
        'items': items,
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
              List variants = List.from(menuSnapshot.data()?['variants'] ?? []);
              for (var i = 0; i < variants.length; i++) {
                if (variants[i]['id'] == variantId) {
                  variants[i]['base_price'] = pricePerUnit;
                  break;
                }
              }
              await menuRef.update({'variants': variants});
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
      return doc.data()!;
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
