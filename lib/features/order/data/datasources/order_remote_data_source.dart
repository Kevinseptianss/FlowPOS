import 'dart:math';
import 'dart:async';

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

  Stream<MonthlyRevenue> listenMonthlyRevenue({required DateTime month});

  Stream<List<OrderModel>> listenAllOrders();
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

  @override
  Stream<MonthlyRevenue> listenMonthlyRevenue({required DateTime month}) {
    final ordersStream = supabaseClient
        .from('orders')
        .stream(primaryKey: ['id']);
    final paymentsStream = supabaseClient
        .from('payments')
        .stream(primaryKey: ['id']);

    return _combineOrdersAndPayments(
      ordersStream: ordersStream,
      paymentsStream: paymentsStream,
      onData: (orderRows, paymentRows) => _calculateMonthlyRevenue(
        month: month,
        orderRows: orderRows,
        paymentRows: paymentRows,
      ),
    );
  }

  @override
  Stream<List<OrderModel>> listenAllOrders() {
    final ordersStream = supabaseClient
        .from('orders')
        .stream(primaryKey: ['id']);
    final paymentsStream = supabaseClient
        .from('payments')
        .stream(primaryKey: ['id']);
    final orderItemsStream = supabaseClient
        .from('order_items')
        .stream(primaryKey: ['id']);

    final controller = StreamController<List<OrderModel>>();

    List<Map<String, dynamic>> latestOrderRows = const [];
    List<Map<String, dynamic>> latestPaymentRows = const [];
    List<Map<String, dynamic>> latestOrderItemRows = const [];

    void emitCombined() {
      controller.add(
        _mapToOrders(
          orderRows: latestOrderRows,
          paymentRows: latestPaymentRows,
          orderItemRows: latestOrderItemRows,
        ),
      );
    }

    late final StreamSubscription<List<Map<String, dynamic>>> ordersSub;
    late final StreamSubscription<List<Map<String, dynamic>>> paymentsSub;
    late final StreamSubscription<List<Map<String, dynamic>>> orderItemsSub;

    ordersSub = ordersStream.listen((rows) {
      latestOrderRows = rows;
      emitCombined();
    }, onError: controller.addError);

    paymentsSub = paymentsStream.listen((rows) {
      latestPaymentRows = rows;
      emitCombined();
    }, onError: controller.addError);

    orderItemsSub = orderItemsStream.listen((rows) {
      latestOrderItemRows = rows;
      emitCombined();
    }, onError: controller.addError);

    controller.onCancel = () async {
      await ordersSub.cancel();
      await paymentsSub.cancel();
      await orderItemsSub.cancel();
    };

    return controller.stream;
  }

  Stream<T> _combineOrdersAndPayments<T>({
    required Stream<List<Map<String, dynamic>>> ordersStream,
    required Stream<List<Map<String, dynamic>>> paymentsStream,
    required T Function(
      List<Map<String, dynamic>> orderRows,
      List<Map<String, dynamic>> paymentRows,
    )
    onData,
  }) {
    final controller = StreamController<T>();

    List<Map<String, dynamic>> latestOrderRows = const [];
    List<Map<String, dynamic>> latestPaymentRows = const [];

    void emitCombined() {
      controller.add(onData(latestOrderRows, latestPaymentRows));
    }

    late final StreamSubscription<List<Map<String, dynamic>>> ordersSub;
    late final StreamSubscription<List<Map<String, dynamic>>> paymentsSub;

    ordersSub = ordersStream.listen((rows) {
      latestOrderRows = rows;
      emitCombined();
    }, onError: controller.addError);

    paymentsSub = paymentsStream.listen((rows) {
      latestPaymentRows = rows;
      emitCombined();
    }, onError: controller.addError);

    controller.onCancel = () async {
      await ordersSub.cancel();
      await paymentsSub.cancel();
    };

    return controller.stream;
  }

  MonthlyRevenue _calculateMonthlyRevenue({
    required DateTime month,
    required List<Map<String, dynamic>> orderRows,
    required List<Map<String, dynamic>> paymentRows,
  }) {
    final yearMonth = '${month.year}${month.month.toString().padLeft(2, '0')}';

    final monthOrderIds = orderRows
        .where((row) {
          final orderNumber = (row['order_number'] as String? ?? '').trim();
          return orderNumber.startsWith('ORD-$yearMonth');
        })
        .map((row) => row['id'] as String?)
        .whereType<String>()
        .toSet();

    if (monthOrderIds.isEmpty) {
      return const MonthlyRevenue.empty();
    }

    int totalRevenue = 0;
    int totalQrisRevenue = 0;
    int totalCashRevenue = 0;

    for (final row in paymentRows) {
      final orderId = row['order_id'] as String?;
      if (orderId == null || !monthOrderIds.contains(orderId)) {
        continue;
      }

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
      totalOrders: monthOrderIds.length,
    );
  }

  List<OrderModel> _mapToOrders({
    required List<Map<String, dynamic>> orderRows,
    required List<Map<String, dynamic>> paymentRows,
    required List<Map<String, dynamic>> orderItemRows,
  }) {
    final paymentByOrderId = <String, Map<String, dynamic>>{};
    for (final paymentRow in paymentRows) {
      final orderId = paymentRow['order_id'] as String?;
      if (orderId != null) {
        paymentByOrderId[orderId] = paymentRow;
      }
    }

    final orderItemsByOrderId = <String, List<Map<String, dynamic>>>{};
    for (final itemRow in orderItemRows) {
      final orderId = itemRow['order_id'] as String?;
      if (orderId == null) {
        continue;
      }

      orderItemsByOrderId.putIfAbsent(orderId, () => []).add(itemRow);
    }

    final orders = orderRows.map((row) {
      final orderId = row['id'] as String? ?? '';
      final paymentRow = paymentByOrderId[orderId];
      final payment = paymentRow == null
          ? const PaymentEntity(
              id: '',
              orderId: '',
              method: '',
              amountPaid: 0,
              amountDue: 0,
              changeGiven: 0,
            )
          : PaymentEntity(
              id: paymentRow['id'] as String? ?? '',
              orderId: paymentRow['order_id'] as String? ?? '',
              method: paymentRow['method'] as String? ?? '',
              amountPaid: (paymentRow['amount_paid'] as num?)?.toInt() ?? 0,
              amountDue: (paymentRow['amount_due'] as num?)?.toInt() ?? 0,
              changeGiven: (paymentRow['change_given'] as num?)?.toInt() ?? 0,
            );

      final items = (orderItemsByOrderId[orderId] ?? const [])
          .map(
            (item) => OrderItem(
              menuItemId: item['menu_item_id'] as String? ?? '',
              quantity: (item['quantity'] as num?)?.toInt() ?? 0,
              unitPrice: (item['unit_price'] as num?)?.toInt() ?? 0,
              notes: item['notes'] as String?,
              modifierSnapshot: item['modifier_snapshot'] as String?,
            ),
          )
          .toList();

      final createdAtRaw = row['created_at'] as String?;
      final createdAt = createdAtRaw == null
          ? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.tryParse(createdAtRaw) ??
                DateTime.fromMillisecondsSinceEpoch(0);

      return OrderModel(
        id: orderId,
        orderNumber: row['order_number'] as String? ?? '',
        tableNumber: (row['table_number'] as num?)?.toInt() ?? 0,
        total: (row['total'] as num?)?.toInt() ?? 0,
        createdAt: createdAt,
        payment: payment,
        items: items,
      );
    }).toList();

    orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return orders;
  }
}
