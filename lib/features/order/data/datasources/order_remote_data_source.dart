import 'dart:math';

import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/order/data/models/order_model.dart';
import 'package:flow_pos/features/order/domain/entities/monthly_revenue.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
  });

  Future<MonthlyRevenue> getMonthlyRevenue({required DateTime month});
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  final SupabaseClient supabaseClient;
  final Uuid _uuid = const Uuid();

  OrderRemoteDataSourceImpl(this.supabaseClient);

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
  }) async {
    final orderId = _uuid.v4();
    final paymentId = _uuid.v4();

    try {
      await supabaseClient.from('orders').insert({
        'id': orderId,
        'order_number': orderNumber,
        'table_number': tableNumber,
        'cashier_id': cashierId,
        'subtotal': subtotal,
        'tax': tax,
        'service_charge': serviceCharge,
        'total': total,
      });

      final orderItemPayload = items
          .map(
            (item) => {
              'id': _uuid.v4(),
              'order_id': orderId,
              'menu_item_id': item.menuItemId,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'notes': item.notes,
              'modifier_snapshot': item.modifierSnapshot,
            },
          )
          .toList();

      await supabaseClient.from('order_items').insert(orderItemPayload);

      final safeAmountPaid = max(amountPaid, 0);
      final amountDue = total;
      final changeGiven = max(0, safeAmountPaid - amountDue);

      await supabaseClient.from('payments').insert({
        'id': paymentId,
        'order_id': orderId,
        'method': method,
        'amount_paid': safeAmountPaid,
        'amount_due': amountDue,
        'change_given': changeGiven,
      });

      return OrderModel(
        id: orderId,
        orderNumber: orderNumber,
        tableNumber: tableNumber,
        total: total,
        paymentId: paymentId,
        paymentMethod: method,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<MonthlyRevenue> getMonthlyRevenue({required DateTime month}) async {
    final yearMonth =
        '${month.year}${month.month.toString().padLeft(2, '0')}';

    try {
      final orderRows = await supabaseClient
          .from('orders')
          .select('id, order_number')
          .like('order_number', 'ORD-$yearMonth%');

      if (orderRows.isEmpty) {
        return const MonthlyRevenue.empty();
      }

      final orderIds = orderRows
          .map((row) => row['id'] as String)
          .toList(growable: false);

      final paymentRows = await supabaseClient
          .from('payments')
          .select('order_id, method, amount_due')
          .inFilter('order_id', orderIds);

      int totalRevenue = 0;
      int totalQrisRevenue = 0;
      int totalCashRevenue = 0;

      for (final row in paymentRows) {
        final amountDue = (row['amount_due'] as num?)?.toInt() ?? 0;
        final method = (row['method'] as String? ?? '').trim().toUpperCase();

        totalRevenue += amountDue;

        if (method == 'QRIS') {
          totalQrisRevenue += amountDue;
        } else if (method == 'CASH') {
          totalCashRevenue += amountDue;
        }
      }

      return MonthlyRevenue(
        totalRevenue: totalRevenue,
        totalQrisRevenue: totalQrisRevenue,
        totalCashRevenue: totalCashRevenue,
        totalOrders: orderIds.length,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
