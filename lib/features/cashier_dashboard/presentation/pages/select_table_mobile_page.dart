import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/table_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/presentation/bloc/cart_bloc.dart';
import 'package:flow_pos/features/cashier_dashboard/domain/entities/cart.dart';
import 'package:flow_pos/features/order/presentation/bloc/order_bloc.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class SelectTableMobilePage extends StatelessWidget {
  final bool isTab;
  const SelectTableMobilePage({super.key, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    final body = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Layanan Pesanan',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppPallete.textPrimary,
            ),
          ),
          Text(
            'Pilih jenis layanan atau meja pelanggan',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: AppPallete.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Active Status Card
          BlocBuilder<TableBloc, TableState>(
            builder: (context, state) {
              final isTakeaway = state.selectedTableNumber == 0;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppPallete.primary,
                      AppPallete.primary.withAlpha(200),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppPallete.primary.withAlpha(60),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isTakeaway ? Icons.shopping_bag_rounded : Icons.table_restaurant_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Status Aktif',
                            style: GoogleFonts.outfit(
                              color: Colors.white.withAlpha(200),
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            isTakeaway ? 'Pesanan: Bungkus (Takeaway)' : 'Sedang Melayani Meja T${state.selectedTableNumber}',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Takeaway Section
          Text(
            'Takeaway',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppPallete.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          BlocBuilder<TableBloc, TableState>(
            builder: (context, state) {
              final isSelected = state.selectedTableNumber == 0;
              return InkWell(
                onTap: () {
                  context.read<TableBloc>().add(const SelectTableEvent(0));
                  context.read<CartBloc>().add(const ClearCartEvent());
                  if (!isTab) Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? AppPallete.secondary.withAlpha(30) : AppPallete.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? AppPallete.secondary : AppPallete.divider,
                      width: 2,
                    ),
                    boxShadow: isSelected ? [] : [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_mall_rounded,
                        color: isSelected ? AppPallete.secondary : AppPallete.textSecondary,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bungkus / Takeaway',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppPallete.secondary : AppPallete.textPrimary,
                              ),
                            ),
                            Text(
                              'Pesanan dibawa pulang langsung',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: AppPallete.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(Icons.check_circle_rounded, color: AppPallete.secondary),
                    ],
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 32),

          // Dine-In Section
          Text(
            'Dine-In (Makan di Tempat)',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppPallete.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<TableBloc, TableState>(
            builder: (context, state) {
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 16,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.0,
                ),
                itemBuilder: (context, index) {
                  final tableNumber = index + 1;
                  final isSelected = state.selectedTableNumber == tableNumber;
                  final isOccupied = state.occupiedTableNumbers.contains(tableNumber);
                  final guestName = state.occupiedTableNames[tableNumber];

                  return InkWell(
                    onTap: () {
                      if (isOccupied) {
                        _showTableActions(context, tableNumber, guestName ?? 'Guest');
                      } else {
                        context.read<TableBloc>().add(
                          SelectTableEvent(tableNumber),
                        );
                        context.read<CartBloc>().add(const ClearCartEvent());
                        if (!isTab) Navigator.of(context).pop();
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? AppPallete.primary 
                            : (isOccupied ? AppPallete.secondary : AppPallete.surface),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: isSelected 
                                ? AppPallete.primary.withAlpha(60) 
                                : (isOccupied ? AppPallete.secondary.withAlpha(40) : Colors.black.withAlpha(10)),
                            blurRadius: isSelected ? 12 : 6,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: isSelected 
                              ? AppPallete.primary 
                              : (isOccupied ? AppPallete.secondary : AppPallete.divider),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'T$tableNumber',
                            style: GoogleFonts.outfit(
                              color: isSelected || isOccupied ? Colors.white : AppPallete.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (isOccupied && !isSelected) ...[
                            const SizedBox(height: 2),
                            Text(
                              guestName ?? 'Isi',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: Colors.white.withAlpha(200),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 2),
                            Icon(
                              Icons.chair_rounded,
                              size: 14,
                              color: isSelected ? Colors.white.withAlpha(150) : AppPallete.textSecondary.withAlpha(100),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 120),
        ],
      ),
    );

    if (isTab) return body;

    return Scaffold(
      backgroundColor: AppPallete.background,
      appBar: AppBar(
        title: Text(
          'Pilih Meja',
          style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppPallete.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
      ),
      body: body,
    );
  }

  void _showTableActions(BuildContext context, int tableNumber, String guestName) {
    final orderBloc = context.read<OrderBloc>();
    final orderState = orderBloc.state;
    double total = 0;
    List<dynamic> activeItems = [];
    
    if (orderState is OrdersLoaded) {
      final matchingOrders = orderState.orders
          .where((o) => o.tableNumber == tableNumber && o.status.trim().toUpperCase() == 'UNPAID')
          .toList();

      if (matchingOrders.isNotEmpty) {
        total = matchingOrders.fold(0.0, (sum, o) => sum + o.total);
        activeItems = matchingOrders.expand((o) => o.items.where((i) => !i.isDeleted)).toList();
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: const BoxDecoration(
          color: AppPallete.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meja T$tableNumber',
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppPallete.textPrimary,
                          ),
                        ),
                        Text(
                          'Atas Nama: $guestName',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppPallete.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppPallete.secondary.withAlpha(20),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0,
                        ).format(total),
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppPallete.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Rincian Pesanan:',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppPallete.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.3,
                  ),
                  child: ListView.separated(
                    shrinkWrap: false,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: activeItems.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: AppPallete.divider.withAlpha(30)),
                    itemBuilder: (context, index) {
                      final item = activeItems[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppPallete.primary.withAlpha(15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${item.quantity}x',
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppPallete.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.menuName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppPallete.textPrimary,
                                    ),
                                  ),
                                  if (item.modifierSnapshot != null && item.modifierSnapshot!.isNotEmpty)
                                    Text(
                                      item.modifierSnapshot!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppPallete.textSecondary,
                                      ),
                                    ),
                                  if (item.notes != null && item.notes!.isNotEmpty)
                                    Text(
                                      item.notes!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppPallete.textSecondary,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp ',
                                decimalDigits: 0,
                              ).format(item.unitPrice * item.quantity),
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: AppPallete.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          context.read<CartBloc>().add(const ClearCartEvent());
                          context.read<TableBloc>().add(SelectTableEvent(tableNumber));
                          Navigator.pop(context); // Pop Modal
                          if (!isTab) Navigator.pop(context); // Pop Page
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          side: const BorderSide(color: AppPallete.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Tambah Pesanan',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: AppPallete.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final cartItems = activeItems.map((item) => Cart(
                            id: const Uuid().v4(),
                            menuItemId: item.menuItemId,
                            name: item.menuName,
                            basePrice: item.unitPrice,
                            quantity: item.quantity,
                            selectedModifiers: const {},
                            totalPrice: item.unitPrice * item.quantity,
                            variantId: item.variantId,
                            notes: item.notes,
                            modifierSnapshot: item.modifierSnapshot,
                          )).toList();
                          context.read<CartBloc>().add(ReplaceCartItemsEvent(cartItems));

                          context.read<TableBloc>().add(SelectTableEvent(tableNumber));
                          Navigator.pop(context); // Pop Modal
                          if (!isTab) Navigator.pop(context, 'PAYOUT'); // Pop Page with signal
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPallete.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: Text(
                          'Bayar / Payout',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
