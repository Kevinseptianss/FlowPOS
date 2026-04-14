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
  final SupabaseClient supabaseClient;
  final Uuid _uuid = const Uuid();

  OrderRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<MonthlyRevenue> getRevenueRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Normalize dates to start and end of day
      final start = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        0,
        0,
        0,
      );
      final end = DateTime(
        endDate.year,
        endDate.month,
        endDate.day,
        23,
        59,
        59,
      );

      final orderRows = await supabaseClient
          .from('orders')
          .select('id')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String())
          .neq('status', 'VOIDED');

      if (orderRows.isEmpty) {
        return const MonthlyRevenue.empty();
      }

      final orderIds = orderRows
          .map((row) => row['id'] as String)
          .toList(growable: false);

      final paymentRows = await supabaseClient
          .from('payments')
          .select('method, amount_due')
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
      final orderItemPayload = items
          .map(
            (item) => {
              'id': _uuid.v4(),
              'menu_item_id': item.menuItemId,
              'quantity': item.quantity,
              'unit_price': item.unitPrice,
              'variant_id': item.variantId,
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
          'p_shift_id': shiftId,
          'p_status': status,
          'p_customer_name': customerName,
        },
      );
      
      final resultMap = (result as Map<String, dynamic>);
      final orderId = resultMap['order_id'] as String;

      // FAIL-SAFE: Explicitly update status to ensure database matches intent
      // Use a separate update to bypass potential RPC limitations
      await supabaseClient
          .from('orders')
          .update({
            'status': status,
            'payment_link': paymentLink,
          })
          .eq('id', orderId);

      // NEW: Clear previous UNPAID orders for this table if this is a PAID order
      // This ensures the table becomes unoccupied after payout.
      if (status == 'PAID' && tableNumber > 0) {
        await supabaseClient
            .from('orders')
            .update({'status': 'SETTLED'})
            .eq('table_number', tableNumber)
            .eq('status', 'UNPAID');
      }
      final paymentId = resultMap['payment_id'] as String?;
      final createdAtRaw = resultMap['created_at'] as String;

      return OrderModel(
        id: orderId,
        orderNumber: orderNumber,
        tableNumber: tableNumber,
        subtotal: subtotal,
        tax: tax.toInt(),
        serviceCharge: serviceCharge.toInt(),
        total: total,
        createdAt: DateTime.parse(createdAtRaw),
        payment: paymentId != null
            ? PaymentEntity(
                id: paymentId,
                orderId: orderId,
                method: method,
                amountPaid: safeAmountPaid,
                amountDue: amountDue,
                changeGiven: changeGiven,
              )
            : null,
        items: items,
        shiftId: shiftId,
        status: status,
        customerName: customerName,
        paymentLink: paymentLink,
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
          .like('order_number', 'ORD-$yearMonth%')
          .neq('status', 'VOIDED');

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
            subtotal,
            tax,
            service_charge,
            total,
            status,
            customer_name,
            payment_link,
            created_at,
            shift_id,
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
              menu_items (
                name
              ),
              quantity,
              unit_price,
              variant_id,
              notes,
              modifier_snapshot,
              is_deleted,
              deleted_at,
              deleted_by_id
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
            : null;

        final orderItemsData = row['order_items'] as List<dynamic>? ?? [];
        final items = orderItemsData.map((item) {
          final menuData = item['menu_items'];
          var menuName = 'Unknown Menu';

          if (menuData is Map<String, dynamic>) {
            menuName = menuData['name'] as String? ?? menuName;
          } else if (menuData is List && menuData.isNotEmpty) {
            final first = menuData.first;
            if (first is Map<String, dynamic>) {
              menuName = first['name'] as String? ?? menuName;
            }
          }

          return OrderItem(
            menuItemId: item['menu_item_id'] as String,
            menuName: menuName,
            quantity: (item['quantity'] as num).toInt(),
            unitPrice: (item['unit_price'] as num).toInt(),
            variantId: item['variant_id'] as String?,
            notes: item['notes'] as String?,
            modifierSnapshot: item['modifier_snapshot'] as String?,
            id: item['id'] as String?,
            isDeleted: item['is_deleted'] as bool? ?? false,
            deletedAt: item['deleted_at'] != null
                ? DateTime.parse(item['deleted_at'] as String)
                : null,
            deletedById: item['deleted_by_id'] as String?,
          );
        }).toList();

        return OrderModel(
          id: row['id'] as String,
          orderNumber: row['order_number'] as String,
          tableNumber: (row['table_number'] as num).toInt(),
          subtotal: (row['subtotal'] as num?)?.toInt() ?? 0,
          tax: (row['tax'] as num?)?.toInt() ?? 0,
          serviceCharge: (row['service_charge'] as num?)?.toInt() ?? 0,
          total: (row['total'] as num).toInt(),
          createdAt: DateTime.parse(row['created_at'] as String),
          payment: payment,
          items: items,
          status: row['status'] as String? ?? 'UNPAID',
          customerName: row['customer_name'] as String?,
          paymentLink: row['payment_link'] as String?,
          shiftId: row['shift_id'] as String?,
        );
      }).toList();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<OrderModel> getOrderById(String orderId) async {
    try {
      final row = await supabaseClient
          .from('orders')
          .select('''
            id,
            order_number,
            table_number,
            subtotal,
            tax,
            service_charge,
            total,
            status,
            created_at,
            shift_id,
            customer_name,
            payment_link,
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
              menu_items (
                name
              ),
              quantity,
              unit_price,
              variant_id,
              notes,
              modifier_snapshot,
              is_deleted,
              deleted_at,
              deleted_by_id
            )
          ''')
          .eq('id', orderId)
          .single();

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
          : null;

      final orderItemsData = row['order_items'] as List<dynamic>? ?? [];
      final items = orderItemsData.map((item) {
        final menuData = item['menu_items'];
        var menuName = 'Unknown Menu';
        if (menuData is Map<String, dynamic>) {
          menuName = menuData['name'] as String? ?? menuName;
        }
        return OrderItem(
          menuItemId: item['menu_item_id'] as String,
          menuName: menuName,
          quantity: (item['quantity'] as num).toInt(),
          unitPrice: (item['unit_price'] as num).toInt(),
          variantId: item['variant_id'] as String?,
          notes: item['notes'] as String?,
          modifierSnapshot: item['modifier_snapshot'] as String?,
          id: item['id'] as String?,
          isDeleted: item['is_deleted'] as bool? ?? false,
          deletedAt: item['deleted_at'] != null
              ? DateTime.parse(item['deleted_at'] as String)
              : null,
          deletedById: item['deleted_by_id'] as String?,
        );
      }).toList();

      return OrderModel(
        id: row['id'] as String,
        orderNumber: row['order_number'] as String,
        tableNumber: (row['table_number'] as num).toInt(),
        subtotal: (row['subtotal'] as num?)?.toInt() ?? 0,
        tax: (row['tax'] as num?)?.toInt() ?? 0,
        serviceCharge: (row['service_charge'] as num?)?.toInt() ?? 0,
        total: (row['total'] as num).toInt(),
        createdAt: DateTime.parse(row['created_at'] as String),
        payment: payment,
        items: items,
        status: row['status'] as String? ?? 'UNPAID',
        customerName: row['customer_name'] as String?,
        paymentLink: row['payment_link'] as String?,
        shiftId: row['shift_id'] as String?,
      );
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
      await supabaseClient
          .from('order_items')
          .update({
            'is_deleted': true,
            'deleted_at': DateTime.now().toIso8601String(),
            'deleted_by_id': deletedById,
          })
          .eq('id', orderItemId);
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
      await supabaseClient.from('payments').insert({
        'id': _uuid.v4(),
        'order_id': orderId,
        'method': method,
        'amount_paid': amountPaid,
        'amount_due': amountDue,
        'change_given': changeGiven,
        'created_at': DateTime.now().toIso8601String(),
      });

      await supabaseClient
          .from('orders')
          .update({'status': 'PAID'})
          .eq('id', orderId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> voidOrder(String orderId) async {
    try {
      await supabaseClient
          .from('orders')
          .update({'status': 'VOIDED'})
          .eq('id', orderId);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
