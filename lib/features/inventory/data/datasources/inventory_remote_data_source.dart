import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
  final SupabaseClient supabaseClient;
  final Uuid _uuid = const Uuid();

  InventoryRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<Map<String, dynamic>>> getStockLevels() async {
    // We join with menu_items and menu_item_variants to get names
    final response = await supabaseClient
        .from('stocks')
        .select('''
          *,
          menu_items:menu_item_id(name, category_id, base_price, price),
          menu_item_variants:variant_id(
            variant_name, 
            option_name,
            base_price,
            menu_items:menu_item_id(name, category_id, base_price, price)
          ),
          purchase_order_items!left(id)
        ''')
        .order('updated_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<Map<String, dynamic>> adjustStock({
    required String stockId,
    required double amount,
    required String reason,
    String? referenceId,
  }) async {
    // 1. Get current stock
    final currentStock = await supabaseClient
        .from('stocks')
        .select()
        .eq('id', stockId)
        .single();
    
    final double currentQty = (currentStock['quantity'] as num).toDouble();
    final double newQty = currentQty + amount;

    // 2. Update stock
    final updatedStock = await supabaseClient
        .from('stocks')
        .update({
          'quantity': newQty,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', stockId)
        .select('''
          *,
          menu_items:menu_item_id(name, category_id, base_price, price),
          menu_item_variants:variant_id(
            variant_name, 
            option_name,
            base_price,
            menu_items:menu_item_id(name, category_id, base_price, price)
          )
        ''')
        .single();
    
    // 3. Create transaction log
    await supabaseClient.from('stock_transactions').insert({
      'stock_id': stockId,
      'type': amount > 0 ? 'IN' : 'OUT',
      'reason': reason,
      'amount': amount.abs(),
      'reference_id': referenceId,
      'created_at': DateTime.now().toIso8601String(),
    });

    return updatedStock;
  }

  @override
  Future<Map<String, dynamic>> createPurchaseOrder({
    required String supplierName,
    required List<Map<String, dynamic>> items,
  }) async {
    // Simple implementation: Create PO header, then items, then update stocks
    final poId = _uuid.v4();
    int totalCost = 0;
    for (var item in items) {
      totalCost += (item['quantity'] as num).toInt() * (item['price_per_unit'] as num).toInt();
    }

    // 1. Create PO
    await supabaseClient.from('purchase_orders').insert({
      'id': poId,
      'supplier_name': supplierName,
      'total_amount': totalCost,
      'status': 'RECEIVED', // Marking as received immediately for this simple flow
      'created_at': DateTime.now().toIso8601String(),
    });

    // 2. Create Items & Update Stock
    for (var item in items) {
      final stockId = item['stock_id'] as String;
      final double qty = (item['quantity'] as num).toDouble();

      await supabaseClient.from('purchase_order_items').insert({
        'po_id': poId,
        'stock_id': stockId,
        'quantity': qty,
        'price_per_unit': item['price_per_unit'],
      });

      // Update current stock levels and log transaction with poId as reference
      await adjustStock(
        stockId: stockId,
        amount: qty,
        reason: 'PURCHASE',
        referenceId: poId,
      );

      // --- AUTOMATION: Sync price_per_unit back to MenuItem/Variant ---
      final stockDetails = await supabaseClient
          .from('stocks')
          .select('menu_item_id, variant_id')
          .eq('id', stockId)
          .single();
      
      final String? menuItemId = stockDetails['menu_item_id'] as String?;
      final String? variantId = stockDetails['variant_id'] as String?;
      final int newBasePrice = (item['price_per_unit'] as num).toInt();

      if (variantId != null) {
        await supabaseClient
            .from('menu_item_variants')
            .update({'base_price': newBasePrice})
            .eq('id', variantId);
      } else if (menuItemId != null) {
        await supabaseClient
            .from('menu_items')
            .update({'base_price': newBasePrice})
            .eq('id', menuItemId);
      }
    }

    final response = await supabaseClient
        .from('purchase_orders')
        .select('*, purchase_order_items(*)')
        .eq('id', poId)
        .single();
    
    return response;
  }

  @override
  Future<List<Map<String, dynamic>>> getPurchaseOrders() async {
    final response = await supabaseClient
        .from('purchase_orders')
        .select('*, purchase_order_items(*)')
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<List<Map<String, dynamic>>> getStockHistory(String stockId) async {
    final response = await supabaseClient
        .from('stock_transactions')
        .select()
        .eq('stock_id', stockId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  @override
  Future<Map<String, dynamic>> getPurchaseOrderById(String poId) async {
    final response = await supabaseClient
        .from('purchase_orders')
        .select('''
          *,
          purchase_order_items(
            *,
            stocks(
               id,
               menu_item_id,
               variant_id,
               menu_items:menu_item_id(name),
               menu_item_variants:variant_id(variant_name, option_name)
            )
          )
        ''')
        .eq('id', poId)
        .single();
    
    return response;
  }
}
