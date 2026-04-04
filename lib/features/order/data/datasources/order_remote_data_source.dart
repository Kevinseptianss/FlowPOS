import 'dart:math';

import 'package:flow_pos/core/error/server_exception.dart';
import 'package:flow_pos/features/order/data/models/order_model.dart';
import 'package:flow_pos/features/order/domain/entities/monthly_revenue.dart';
import 'package:flow_pos/features/order/domain/entities/order_item.dart';
import 'package:flow_pos/features/order/domain/entities/payment_entity.dart';
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

  Future<List<OrderModel>> getAllOrders();
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
    try {
      final orderItemPayload = items
          .map(
            (item) => {
              'id': _uuid.v4(),
              'menu_item_id': item.menuItemId,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'notes': item.notes,
              'modifier_snapshot': item.modifierSnapshot,
            },
          )
          .toList();

      final safeAmountPaid = max(amountPaid, 0);
      final amountDue = total;
      final changeGiven = max(0, safeAmountPaid - amountDue);

      final result = await supabaseClient.rpc(
        'create_order_atomic',
        params: {
          'p_order_number': orderNumber,
          'p_table_number': tableNumber,
          'p_cashier_id': cashierId,
          'p_subtotal': subtotal,
          'p_tax': tax,
          'p_service_charge': serviceCharge,
          'p_total': total,
          'p_method': method,
          'p_amount_paid': safeAmountPaid,
          'p_amount_due': amountDue,
          'p_change_given': changeGiven,
          'p_items': orderItemPayload,
        },
      );

      final resultMap = (result as Map<String, dynamic>);
      final orderId = resultMap['order_id'] as String;
      final paymentId = resultMap['payment_id'] as String;
      final createdAtRaw = resultMap['created_at'] as String;

      return OrderModel(
        id: orderId,
        orderNumber: orderNumber,
        tableNumber: tableNumber,
        total: total,
        createdAt: DateTime.parse(createdAtRaw),
        payment: PaymentEntity(
          id: paymentId,
          orderId: orderId,
          method: method,
          amountPaid: safeAmountPaid,
          amountDue: amountDue,
          changeGiven: changeGiven,
        ),
        items: items,
      );
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<MonthlyRevenue> getMonthlyRevenue({required DateTime month}) async {
    final yearMonth = '${month.year}${month.month.toString().padLeft(2, '0')}';

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

  @override
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final orderRows = await supabaseClient
          .from('orders')
          .select('''
            id,
            order_number,
            table_number,
            total,
            created_at,
            payments (
              id,
              order_id,
              method,
              amount_paid,
              amount_due,
              change_given
            ),
            order_items (
              id,
              order_id,
              menu_item_id,
              quantity,
              unit_price,
              notes,
              modifier_snapshot
            )
          ''')
          .order('created_at', ascending: false);

      return orderRows.map((row) {
        final paymentData = row['payments'] as List<dynamic>? ?? [];
        final payment = paymentData.isNotEmpty
            ? PaymentEntity(
                id: paymentData[0]['id'] as String,
                orderId: paymentData[0]['order_id'] as String,
                method: paymentData[0]['method'] as String,
                amountPaid: (paymentData[0]['amount_paid'] as num).toInt(),
                amountDue: (paymentData[0]['amount_due'] as num).toInt(),
                changeGiven: (paymentData[0]['change_given'] as num).toInt(),
              )
            : const PaymentEntity(
                id: '',
                orderId: '',
                method: '',
                amountPaid: 0,
                amountDue: 0,
                changeGiven: 0,
              );

        final orderItemsData = row['order_items'] as List<dynamic>? ?? [];
        final items = orderItemsData
            .map(
              (item) => OrderItem(
                menuItemId: item['menu_item_id'] as String,
                quantity: item['quantity'] as int,
                unitPrice: (item['unit_price'] as num).toInt(),
                notes: item['notes'] as String?,
                modifierSnapshot: item['modifier_snapshot'] as String?,
              ),
            )
            .toList();

        return OrderModel(
          id: row['id'] as String,
          orderNumber: row['order_number'] as String,
          tableNumber: row['table_number'] as int,
          total: (row['total'] as num).toInt(),
          createdAt: DateTime.parse(row['created_at'] as String),
          payment: payment,
          items: items,
        );
      }).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
