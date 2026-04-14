import 'dart:ui';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/inventory/domain/entities/purchase_order.dart';
import 'package:flow_pos/features/inventory/domain/entities/stock.dart';
import 'package:flow_pos/features/inventory/domain/entities/stock_transaction.dart';
import 'package:flow_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:flow_pos/features/order/domain/entities/order_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class OwnerStockDetailPage extends StatefulWidget {
  final Stock stock;
  const OwnerStockDetailPage({super.key, required this.stock});

  static Route route(Stock stock) {
    return MaterialPageRoute(
      builder: (context) => OwnerStockDetailPage(stock: stock),
    );
  }

  @override
  State<OwnerStockDetailPage> createState() => _OwnerStockDetailPageState();
}

class _OwnerStockDetailPageState extends State<OwnerStockDetailPage> {
  List<StockTransaction>? _localHistory;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<InventoryBloc>().add(GetStockHistoryEvent(widget.stock.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is InventoryFailure) {
          showSnackbar(context, state.message);
        } else if (state is PurchaseOrderDetailLoaded) {
          _showPODetailDialog(context, state.po);
        } else if (state is OrderDetailLoaded) {
          _showSaleDetailDialog(context, state.order);
        }
      },
      builder: (context, state) {
        if (state is StockHistoryLoaded) {
          _localHistory = state.transactions;
        }
        
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          body: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(context),
              _buildStockInfoCard(context),
              _buildHistoryHeader(context),
              if (state is StockHistoryLoading && _localHistory == null)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_localHistory != null)
                _buildHistoryList(_localHistory!)
              else
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: Text('Gagal memuat riwayat')),
                ),
            ],
          ),
          bottomNavigationBar: _buildBottomActions(context),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppPallete.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Detail Inventori',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w800,
          color: AppPallete.textPrimary,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildStockInfoCard(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppPallete.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.inventory_2_rounded, color: AppPallete.primary, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.stock.itemName,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppPallete.textPrimary,
                        ),
                      ),
                      if (widget.stock.variantName != null)
                        Text(
                          widget.stock.variantName!,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: AppPallete.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(height: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoBit(
                  'Stok',
                  '${widget.stock.quantity.toInt()} Unit',
                  widget.stock.quantity <= widget.stock.minThreshold ? Colors.orange : Colors.green,
                ),
                _buildInfoBit(
                  'Harga Jual',
                  currencyFormatter.format(widget.stock.price ?? 0),
                  AppPallete.primary,
                ),
                _buildInfoBit(
                  'HPP',
                  currencyFormatter.format(widget.stock.basePrice ?? 0),
                  AppPallete.textSecondary,
                ),
                _buildMarginBit(widget.stock.price, widget.stock.basePrice),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarginBit(int? price, int? basePrice) {
    if (price == null || basePrice == null || price <= 0) {
      return _buildInfoBit('Margin', '-', AppPallete.textSecondary);
    }
    final marginVal = ((price - basePrice) / price) * 100;
    final color = marginVal > 30 ? Colors.green : (marginVal > 15 ? Colors.orange : Colors.red);
    
    return _buildInfoBit(
      'Margin',
      '${marginVal.toStringAsFixed(1)}%',
      color,
    );
  }

  Widget _buildInfoBit(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            color: AppPallete.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Riwayat Stok',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppPallete.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppPallete.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Terbaru',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppPallete.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(List<StockTransaction> transactions) {
    if (transactions.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('Belum ada riwayat transaksi')),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final tx = transactions[index];
            final isPositive = tx.type == 'IN';
            final icon = _getTransactionIcon(tx.reason);
            final color = _getTransactionColor(tx.type, tx.reason);
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black.withAlpha(5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _handleHistoryClick(context, tx),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withAlpha(15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: color, size: 20),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTransactionLabel(tx.reason),
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: AppPallete.textPrimary,
                                  ),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy, HH:mm').format(tx.createdAt),
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: AppPallete.textSecondary,
                                  ),
                                ),
                                if (tx.referenceId != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      tx.reason == 'SALE' ? 'Receipt #${tx.referenceId!.substring(0, 8).toUpperCase()}' : 'Ref: ${tx.referenceId}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: tx.reason == 'SALE' ? AppPallete.primary : AppPallete.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${isPositive ? '+' : ''}${tx.amount.toInt()}',
                                style: GoogleFonts.outfit(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: color,
                                ),
                              ),
                              Text(
                                'Unit',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: AppPallete.textSecondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          childCount: transactions.length,
        ),
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPallete.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: () => _showAdjustmentModal(context),
              child: Text(
                'Penyesuaian Stok',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTransactionIcon(String reason) {
    switch (reason) {
      case 'PURCHASE': return Icons.add_business_rounded;
      case 'SALE': return Icons.shopping_basket_rounded;
      case 'ADJUSTMENT':
      case 'CORRECTION': return Icons.edit_note_rounded;
      case 'WASTE': return Icons.delete_sweep_rounded;
      default: return Icons.swap_horiz_rounded;
    }
  }

  Color _getTransactionColor(String type, String reason) {
    if (type == 'IN') return Colors.green;
    if (reason == 'SALE') return AppPallete.primary;
    if (reason == 'WASTE') return Colors.red;
    return Colors.orange;
  }

  String _getTransactionLabel(String reason) {
    switch (reason) {
      case 'PURCHASE': return 'Pembelian (PO)';
      case 'SALE': return 'Terjual (Sales)';
      case 'ADJUSTMENT':
      case 'CORRECTION': return 'Penyesuaian Manual';
      case 'WASTE': return 'Barang Rusak/Waste';
      default: return 'Transaksi Stok';
    }
  }

  void _handleHistoryClick(BuildContext context, StockTransaction tx) {
    if ((tx.reason == 'SALE' || tx.reason == 'PURCHASE') && tx.referenceId == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Data Tidak Ditemukan', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          content: Text('Maaf, transaksi lama ini tidak memiliki referensi data detail. Detail hanya tersedia untuk transaksi baru.', style: GoogleFonts.outfit()),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    if (tx.reason == 'SALE') {
      context.read<InventoryBloc>().add(GetOrderByIdEvent(tx.referenceId!));
    } else if (tx.reason == 'PURCHASE') {
      context.read<InventoryBloc>().add(GetPurchaseOrderEvent(tx.referenceId!));
    } else if (tx.reason == 'ADJUSTMENT' || tx.reason == 'CORRECTION' || tx.reason == 'WASTE') {
      _showAdjustmentDetailModal(context, tx);
    }
  }

  void _showSaleDetailDialog(BuildContext context, OrderEntity order) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Text('Detail Penjualan', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: AppPallete.textPrimary)),
            const SizedBox(height: 4),
            Text(order.orderNumber, style: GoogleFonts.outfit(fontSize: 14, color: AppPallete.textSecondary)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.menuName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppPallete.textPrimary)),
                          Text('${item.quantity} x ${currencyFormatter.format(item.unitPrice)}', 
                            style: GoogleFonts.outfit(fontSize: 12, color: AppPallete.textSecondary)),
                        ],
                      ),
                    ),
                    Text(currencyFormatter.format(item.unitPrice * item.quantity), 
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppPallete.primary)),
                  ],
                ),
              )),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: AppPallete.divider),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppPallete.textPrimary)),
                  Text(currencyFormatter.format(order.total), 
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: AppPallete.primary)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Metode Bayar', style: GoogleFonts.outfit(fontSize: 12, color: AppPallete.textSecondary)),
                  Text(order.payment?.method ?? (order.status == 'UNPAID' ? 'BELUM BAYAR' : 'LUNAS'), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: AppPallete.textPrimary)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPallete.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('TUTUP', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPODetailDialog(BuildContext context, PurchaseOrder po) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Column(
          children: [
            Text('Detail Pembelian (PO)', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: AppPallete.textPrimary)),
            const SizedBox(height: 4),
            Text('Supplier: ${po.supplierName}', style: GoogleFonts.outfit(fontSize: 14, color: AppPallete.textSecondary)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...po.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.itemName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppPallete.textPrimary)),
                          Text('${item.quantity.toInt()} x ${currencyFormatter.format(item.pricePerUnit)}', 
                            style: GoogleFonts.outfit(fontSize: 12, color: AppPallete.textSecondary)),
                        ],
                      ),
                    ),
                    Text(currencyFormatter.format(item.pricePerUnit * item.quantity), 
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.green)),
                  ],
                ),
              )),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(color: AppPallete.divider),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Biaya', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: AppPallete.textPrimary)),
                  Text(currencyFormatter.format(po.totalAmount), 
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Status', style: GoogleFonts.outfit(fontSize: 12, color: AppPallete.textSecondary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(po.status, style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPallete.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text('TUTUP', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdjustmentDetailModal(BuildContext context, StockTransaction tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Detail Penyesuaian', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900)),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Tanggal', DateFormat('dd MMM yyyy, HH:mm').format(tx.createdAt)),
            _buildDetailRow('Jumlah', '${tx.type == 'IN' ? '+' : ''}${tx.amount.toInt()} Unit'),
            _buildDetailRow('Alasan', tx.reason),
            const SizedBox(height: 12),
             Text('Catatan:', style: GoogleFonts.outfit(fontSize: 12, color: AppPallete.textSecondary)),
             const SizedBox(height: 4),
             Container(
               width: double.infinity,
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: AppPallete.background,
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Text(
                 tx.reason == 'ADJUSTMENT' ? 'Penyesuaian Manual' : tx.reason, 
                 style: GoogleFonts.outfit(fontWeight: FontWeight.w500),
               ),
             ),
             const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.outfit(color: AppPallete.textSecondary)),
          Text(value, style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showAdjustmentModal(BuildContext context) {
    final qtyController = TextEditingController();
    final reasonController = TextEditingController();
    bool isAddition = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              left: 24,
              right: 24,
              top: 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Penyesuaian Stok',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Toggle Add/Subtract
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => isAddition = true),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isAddition ? Colors.green.withAlpha(20) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isAddition ? Colors.green : AppPallete.divider,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_rounded, color: isAddition ? Colors.green : AppPallete.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                'Tambah',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: isAddition ? Colors.green : AppPallete.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setModalState(() => isAddition = false),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !isAddition ? Colors.red.withAlpha(20) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: !isAddition ? Colors.red : AppPallete.divider,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_rounded, color: !isAddition ? Colors.red : AppPallete.textSecondary),
                              const SizedBox(width: 8),
                              Text(
                                'Kurangi',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: !isAddition ? Colors.red : AppPallete.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: qtyController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: AppPallete.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Jumlah Unit',
                    labelStyle: GoogleFonts.outfit(),
                    prefixIcon: const Icon(Icons.numbers_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppPallete.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 2,
                  style: GoogleFonts.outfit(
                    color: AppPallete.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Keterangan / Alasan',
                    labelStyle: GoogleFonts.outfit(),
                    hintText: 'Contoh: Koreksi stok, Barang rusak, dll',
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.description_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAddition ? Colors.green : Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () {
                      final amount = double.tryParse(qtyController.text);
                      if (amount != null && amount > 0) {
                        final finalAmount = isAddition ? amount : -amount;
                        final reason = reasonController.text.isEmpty ? 'Penyesuaian Manual' : reasonController.text;
                        
                        final inventoryBloc = context.read<InventoryBloc>();
                        inventoryBloc.add(AdjustStockEvent(
                          stockId: widget.stock.id,
                          amount: finalAmount,
                          reason: reason,
                        ));
                        
                        Navigator.pop(context);
                        Future.delayed(const Duration(milliseconds: 500), () {
                          if (mounted) {
                            inventoryBloc.add(GetStockHistoryEvent(widget.stock.id));
                          }
                        });
                      }
                    },
                    child: Text(
                      'KONFIRMASI ${isAddition ? 'TAMBAH' : 'KURANGI'}',
                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
