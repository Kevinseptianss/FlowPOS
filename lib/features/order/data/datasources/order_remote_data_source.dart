import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/order/data/models/order_model.dart';
import 'package:flow_pos/features/order/domain/entities/monthly_revenue.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/order/domain/entities/payment_entity.dart';

abstract interface class OrderRemoteDataSource {
  Future<OrderModel> createOrder({
    required String orderNumber,
    required int tableNumber,
    required String cashierId,
    required int subtotal,
    required double tax,
    required double serviceCharge,
    required int total,
    required String method,
    required int amountPaid,
    required List<OrderItem> items,
    String? shiftId,
    String status = 'UNPAID',
    String? customerName,
    String? paymentLink,
  });

  Future<MonthlyRevenue> getMonthlyRevenue({required DateTime month});

  Future<MonthlyRevenue> getRevenueRange({
    required DateTime startDate,
    required DateTime endDate,
  });

  Future<List<OrderModel>> getAllOrders();
  Future<OrderModel> getOrderById(String orderId);
  Future<void> softDeleteOrderItem({
    required String orderItemId,
    required String deletedById,
  });
  Future<void> settleOrder({
    required String orderId,
    required String method,
    required int amountPaid,
    required int amountDue,
    required int changeGiven,
  });
  Future<void> voidOrder(String orderId);
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final FirebaseFirestore _firestore;

  OrderRemoteDataSourceImpl(this._firestore);

  @override
  Future<OrderModel> createOrder({
    required String orderNumber,
    required int tableNumber,
    required String cashierId,
    required int subtotal,
    required double tax,
    required double serviceCharge,
    required int total,
    required String method,
    required int amountPaid,
    required List<OrderItem> items,
    String? shiftId,
    String status = 'UNPAID',
    String? customerName,
    String? paymentLink,
  }) async {
    try {
      final docRef = _firestore.collection('orders').doc();
      final orderId = docRef.id;

      final safeAmountPaid = max(amountPaid, 0);
      final amountDue = total;
      final changeGiven = max(0, safeAmountPaid - amountDue);

      final List<Map<String, dynamic>> itemsData = items.map((item) => {
        'id': item.id ?? _firestore.collection('temp').doc().id,
        'menu_item_id': item.menuItemId,
        'menu_name': item.menuName,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'cost_price': item.costPrice,
        'variant_id': item.variantId,
        'notes': item.notes,
        'modifier_snapshot': item.modifierSnapshot,
        'is_deleted': item.isDeleted,
      }).toList();

      final totalHpp = items.where((i) => !i.isDeleted).fold<int>(0, (sum, item) => sum + (item.costPrice));

      // Even if UNPAID, we store the method for reporting/history purposes (e.g., QRIS)
      final Map<String, dynamic>? paymentData = (status == 'PAID' || amountPaid > 0 || method != 'NONE') ? {
        'id': _firestore.collection('temp').doc().id,
        'method': method,
        'amount_paid': safeAmountPaid,
        'amount_due': amountDue,
        'change_given': changeGiven,
        'created_at': FieldValue.serverTimestamp(),
      } : null;

      final orderData = {
        'id': orderId,
        'order_number': orderNumber,
        'table_number': tableNumber,
        'cashier_id': cashierId,
        'subtotal': subtotal,
        'tax': tax,
        'service_charge': serviceCharge,
        'total': total,
        'status': status,
        'customer_name': customerName,
        'payment_link': paymentLink,
        'shift_id': shiftId,
        'total_hpp': totalHpp,
        'items': itemsData,
        'payment': paymentData,
        'created_at': FieldValue.serverTimestamp(),
      };

      await docRef.set(orderData);

      // --- DEDUCT STOCK IF PAID ---
      if (status == 'PAID') {
        await _updateStockForItems(items, orderId);
      }

      // If status is PAID, we might want to clear other UNPAID orders for the same table
      if (status == 'PAID' && tableNumber > 0) {
        final batch = _firestore.batch();
        final sameTableOrders = await _firestore
            .collection('orders')
            .where('table_number', isEqualTo: tableNumber)
            .where('status', isEqualTo: 'UNPAID')
            .get();
        
        for (var doc in sameTableOrders.docs) {
          if (doc.id != orderId) {
            batch.update(doc.reference, {'status': 'SETTLED'});
          }
        }
        await batch.commit();
      }

      return _mapToModel(orderId, orderData..['created_at'] = DateTime.now());
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  Future<void> _updateStockForItems(List<OrderItem> items, String orderId) async {
    for (var item in items) {
      if (item.isDeleted) continue;

      // Find the stock document for this menu_item and variant
      final stockQuery = await _firestore.collection('stocks')
          .where('menu_item_id', isEqualTo: item.menuItemId)
          .where('variant_id', isEqualTo: item.variantId)
          .limit(1)
          .get();
      
      if (stockQuery.docs.isNotEmpty) {
        final stockDoc = stockQuery.docs.first;
        final stockId = stockDoc.id;
        final currentQty = (stockDoc.data()['quantity'] as num?)?.toDouble() ?? 0;
        final newQty = currentQty - item.quantity;

        // Update stock
        await stockDoc.reference.update({
          'quantity': newQty,
          'updated_at': FieldValue.serverTimestamp(),
        });

        // Log transaction
        await _firestore.collection('stock_transactions').add({
          'stock_id': stockId,
          'type': 'OUT',
          'reason': 'SALE',
          'amount': item.quantity.toDouble(),
          'reference_id': orderId,
          'created_at': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  @override
  Future<MonthlyRevenue> getMonthlyRevenue({required DateTime month}) async {
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0, 23, 59, 59);
    return getRevenueRange(startDate: start, endDate: end);
  }

  @override
  Future<MonthlyRevenue> getRevenueRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('created_at', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      int totalRevenue = 0;
      int totalHpp = 0;
      int totalQrisRevenue = 0;
      int totalCashRevenue = 0;
      int totalTransferRevenue = 0;
      int totalCardRevenue = 0;
      int totalOrders = 0;

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = (data['status'] as String? ?? '').toUpperCase();
        if (status == 'VOIDED') continue;

        totalOrders++;
        
        // Only count PAID or SETTLEMENT or SETTLED as revenue
        if (status != 'PAID' && 
            status != 'SETTLEMENT' && 
            status != 'SETTLED' && 
            status != 'TERBAYAR' &&
            status != 'CAPTURE' &&
            status != 'SUCCESS') {
           continue; 
        }

        final payment = data['payment'] as Map<String, dynamic>?;
        if (payment != null) {
          final amount = (payment['amount_due'] as num?)?.toInt() ?? 0;
          final method = (payment['method'] as String? ?? '').toUpperCase();

          totalRevenue += amount;
          totalHpp += (data['total_hpp'] as num?)?.toInt() ?? 0;
          if (method == 'QRIS') {
            totalQrisRevenue += amount;
          } else if (method == 'CASH' || method == 'TUNAI') {
            totalCashRevenue += amount;
          } else if (method == 'TRANSFER') {
            totalTransferRevenue += amount;
          } else if (method == 'CARD' || method == 'KARTU') {
            totalCardRevenue += amount;
          }
        }
      }

      return MonthlyRevenue(
        totalRevenue: totalRevenue,
        totalHpp: totalHpp,
        totalQrisRevenue: totalQrisRevenue,
        totalCashRevenue: totalCashRevenue,
        totalTransferRevenue: totalTransferRevenue,
        totalCardRevenue: totalCardRevenue,
        totalOrders: totalOrders,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => _mapToModel(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final doc = await _firestore.collection('orders').doc(orderId).get();
      if (!doc.exists) throw const ServerException('Order not found');
      return _mapToModel(doc.id, doc.data()!);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> softDeleteOrderItem({
    required String orderItemId,
    required String deletedById,
  }) async {
    try {
      // We need to find the order containing this item
      // In a real app, we should pass orderId. For now, we'll query.
      // Searching all orders for the item ID in the items list.
      final orders = await _firestore.collection('orders').get();
      for (var doc in orders.docs) {
        List items = List.from(doc.data()['items'] ?? []);
        bool found = false;
        for (var i = 0; i < items.length; i++) {
          if (items[i]['id'] == orderItemId) {
            items[i]['is_deleted'] = true;
            items[i]['deleted_at'] = Timestamp.now();
            items[i]['deleted_by_id'] = deletedById;
            found = true;
            break;
          }
        }
        if (found) {
          await doc.reference.update({'items': items});
          return;
        }
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> settleOrder({
    required String orderId,
    required String method,
    required int amountPaid,
    required int amountDue,
    required int changeGiven,
  }) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': 'PAID',
        'payment': {
          'id': _firestore.collection('temp').doc().id,
          'method': method,
          'amount_paid': amountPaid,
          'amount_due': amountDue,
          'change_given': changeGiven,
          'created_at': FieldValue.serverTimestamp(),
        }
      });

      // --- DEDUCT STOCK ON SETTLE ---
      final orderDoc = await _firestore.collection('orders').doc(orderId).get();
      if (orderDoc.exists) {
        final data = orderDoc.data();
        if (data != null && data['items'] != null) {
          final itemsData = data['items'] as List;
          final List<OrderItem> items = itemsData.map((item) => OrderItem(
            menuItemId: item['menu_item_id'] ?? '',
            menuName: item['menu_name'] ?? 'Unknown',
            quantity: item['quantity'] ?? 0,
            unitPrice: item['unit_price'] ?? 0,
            variantId: item['variant_id'],
          )).toList();
          
          await _updateStockForItems(items, orderId);
        }
      }
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> voidOrder(String orderId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({'status': 'VOIDED'});
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  OrderModel _mapToModel(String id, Map<String, dynamic> data) {
    final paymentData = data['payment'] as Map<String, dynamic>?;
    final itemsData = data['items'] as List<dynamic>? ?? [];

    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return OrderModel(
      id: id,
      orderNumber: data['order_number'] ?? '',
      tableNumber: data['table_number'] ?? 0,
      subtotal: (data['subtotal'] as num?)?.toInt() ?? 0,
      tax: (data['tax'] as num?)?.toInt() ?? 0,
      serviceCharge: (data['service_charge'] as num?)?.toInt() ?? 0,
      total: (data['total'] as num?)?.toInt() ?? 0,
      createdAt: parseDateTime(data['created_at']),
      status: data['status'] ?? 'UNPAID',
      customerName: data['customer_name'],
      paymentLink: data['payment_link'],
      shiftId: data['shift_id'],
      payment: paymentData != null ? PaymentEntity(
        id: paymentData['id'] ?? '',
        orderId: id,
        method: paymentData['method'] ?? '',
        amountPaid: (paymentData['amount_paid'] as num?)?.toInt() ?? 0,
        amountDue: (paymentData['amount_due'] as num?)?.toInt() ?? 0,
        changeGiven: (paymentData['change_given'] as num?)?.toInt() ?? 0,
      ) : null,
      items: itemsData.map((item) {
        final deletedAtRaw = item['deleted_at'];
        DateTime? deletedAt;
        if (deletedAtRaw is Timestamp) deletedAt = deletedAtRaw.toDate();
        if (deletedAtRaw is DateTime) deletedAt = deletedAtRaw;

        return OrderItem(
          id: item['id'],
          menuItemId: item['menu_item_id'] ?? '',
          menuName: item['menu_name'] ?? 'Unknown',
          quantity: item['quantity'] ?? 0,
          unitPrice: item['unit_price'] ?? 0,
          costPrice: item['cost_price'] ?? 0,
          variantId: item['variant_id'],
          notes: item['notes'],
          modifierSnapshot: item['modifier_snapshot'],
          isDeleted: item['is_deleted'] ?? false,
          deletedAt: deletedAt,
          deletedById: item['deleted_by_id'],
        );
      }).toList(),
    );
  }
}
