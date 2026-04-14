import 'dart:ui';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/core/utils/currency_input_formatter.dart';
import 'package:flow_pos/features/inventory/domain/entities/stock.dart';
import 'package:flow_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:flow_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class OwnerPurchaseOrderPage extends StatefulWidget {
  static MaterialPageRoute route() => MaterialPageRoute(builder: (_) => const OwnerPurchaseOrderPage());
  const OwnerPurchaseOrderPage({super.key});

  @override
  State<OwnerPurchaseOrderPage> createState() => _OwnerPurchaseOrderPageState();
}

class _OwnerPurchaseOrderPageState extends State<OwnerPurchaseOrderPage> {
  final _supplierController = TextEditingController();
  final List<Map<String, dynamic>> _selectedItems = [];
  int _currentStep = 0;
  String _searchQuery = '';
  String _selectedCategoryId = 'all';

  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(GetStockLevelsEvent());
    context.read<CategoryBloc>().add(GetAllCategoriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is PurchaseOrderCreated) {
          showSnackbar(context, 'Purchase Order Berhasil Diarsipkan!');
          Navigator.pop(context);
        } else if (state is InventoryFailure) {
          showSnackbar(context, state.message);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: Text(
            'LOGISTIK & PENGADAAN',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 14),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          foregroundColor: AppPallete.textPrimary,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: _currentStep == 0 
                  ? _buildItemSelectionPhase() 
                  : _buildFinalizationPhase(),
            ),
          ],
        ),
        bottomNavigationBar: _buildActionDock(),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle(0, 'Pilih Produk', Icons.shopping_basket_rounded),
          _buildStepDivider(),
          _buildStepCircle(1, 'Konfirmasi & Simpan', Icons.description_rounded),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;

    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isActive ? AppPallete.primary : (isDone ? AppPallete.success : Colors.grey[200]),
            shape: BoxShape.circle,
            boxShadow: isActive ? [BoxShadow(color: AppPallete.primary.withAlpha(80), blurRadius: 10, offset: const Offset(0, 4))] : [],
          ),
          child: Icon(isDone ? Icons.check_rounded : icon, color: isActive || isDone ? Colors.white : Colors.grey[400], size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? AppPallete.primary : Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider() {
    return Container(
      width: 60,
      height: 2,
      margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      color: Colors.grey[200],
    );
  }

  Widget _buildItemSelectionPhase() {
    return Column(
      children: [
        // --- PREMIUM SEARCH BAR ---
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 20, offset: const Offset(0, 4)),
              ],
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: AppPallete.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppPallete.primary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),

        // --- STANDARDIZED CATEGORY FILTER ---
        BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            final categories = <Map<String, String>>[{'id': 'all', 'name': 'Semua'}];
            if (state is CategoryLoaded) {
              for (var cat in state.categories) {
                categories.add({'id': cat.id, 'name': cat.name});
              }
            }
            return SizedBox(
              height: 44,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategoryId == cat['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ChoiceChip(
                      label: Text(
                        cat['name']!,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (s) => setState(() => _selectedCategoryId = cat['id']!),
                      selectedColor: AppPallete.primary,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : AppPallete.textPrimary),
                      backgroundColor: Colors.white,
                      showCheckmark: false,
                      elevation: isSelected ? 4 : 0,
                      shadowColor: AppPallete.primary.withAlpha(80),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: isSelected ? AppPallete.primary : Colors.grey[200]!),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // --- PRODUCT GRID ---
        Expanded(
          child: BlocBuilder<InventoryBloc, InventoryState>(
            builder: (context, state) {
              if (state is InventoryLoaded) {
                final filtered = state.stocks.where((s) {
                  final matchesSearch = s.itemName.toLowerCase().contains(_searchQuery.toLowerCase());
                  final matchesCategory = _selectedCategoryId == 'all' || s.categoryId == _selectedCategoryId;
                  return matchesSearch && matchesCategory;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Produk tidak ditemukan', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 400,
                    mainAxisExtent: 100,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final stock = filtered[index];
                    final isSelected = _selectedItems.any((i) => i['stock_id'] == stock.id);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? AppPallete.primary.withAlpha(10) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppPallete.primary : Colors.transparent, width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        title: Text(stock.itemName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text('Sisa: ${stock.quantity.toInt()} Unit', style: GoogleFonts.outfit(fontSize: 12)),
                        trailing: IconButton(
                          icon: Icon(isSelected ? Icons.edit_rounded : Icons.add_circle_outline_rounded, color: AppPallete.primary),
                          onPressed: () => _addItemToPO(stock),
                        ),
                      ),
                    );
                  },
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFinalizationPhase() {
    num total = 0;
    for (var item in _selectedItems) {
      total += item['quantity'] * item['price_per_unit'];
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 20)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DETAIL LOGISTIK', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 16),
                TextField(
                  controller: _supplierController,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppPallete.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'NAMA SUPPLIER / VENDOR',
                    labelStyle: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold),
                    prefixIcon: const Icon(Icons.business_rounded, color: AppPallete.primary),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 32),
                Text('DAFTAR ITEM (${_selectedItems.length})', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 16),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _selectedItems.length,
                  separatorBuilder: (context, index) => const Divider(height: 32),
                  itemBuilder: (context, index) {
                    final item = _selectedItems[index];
                    return Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(color: AppPallete.primary.withAlpha(10), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.inventory_2_rounded, size: 18, color: AppPallete.primary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item['name'], style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('${item['quantity']} Unit @ ${formatRupiah(item['price_per_unit'])}', style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Text(formatRupiah((item['quantity'] as num) * (item['price_per_unit'] as num)), style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: AppPallete.primary)),
                        const SizedBox(width: 8),
                        IconButton(icon: const Icon(Icons.remove_circle_outline_rounded, color: Colors.red, size: 20), onPressed: () => setState(() => _selectedItems.removeAt(index))),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('ESTIMASI TOTAL BIAYA', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.grey, fontSize: 11)),
                    Text(formatRupiah(total), style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: AppPallete.primary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionDock() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          if (_currentStep == 1)
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  side: const BorderSide(color: Colors.grey),
                ),
                onPressed: () => setState(() => _currentStep = 0),
                child: Text('KEMBALI', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
            ),
          if (_currentStep == 1) const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppPallete.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _currentStep == 0 
                  ? (_selectedItems.isNotEmpty ? () => setState(() => _currentStep = 1) : null) 
                  : _submitPO,
              child: Text(
                _currentStep == 0 ? 'LANJUTKAN (${_selectedItems.length} ITEM)' : 'ARCHIVE PURCHASE ORDER',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _addItemToPO(Stock stock) {
    final existing = _selectedItems.indexWhere((i) => i['stock_id'] == stock.id);
    
    // Default to empty strings as per request
    final qtyController = TextEditingController(
      text: existing != -1 ? _selectedItems[existing]['quantity'].toString() : '',
    );
    final priceController = TextEditingController(
      text: existing != -1 ? _selectedItems[existing]['price_per_unit'].toString() : '',
    );

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Dialog(
          backgroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppPallete.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.add_shopping_cart_rounded, color: AppPallete.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tambah Item',
                            style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 18, color: AppPallete.textPrimary),
                          ),
                          Text(
                            stock.itemName,
                            style: GoogleFonts.outfit(fontSize: 13, color: AppPallete.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // --- QUANTITY FIELD ---
                Text('JUMLAH PENGADAAN', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyController, 
                  keyboardType: TextInputType.number, 
                  autofocus: true,
                  style: GoogleFonts.outfit(
                    fontSize: 20, 
                    fontWeight: FontWeight.bold,
                    color: AppPallete.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: '0',
                    suffixText: 'Unit',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.inventory_rounded, color: AppPallete.primary),
                  ),
                ),
                const SizedBox(height: 24),

                // --- PRICE FIELD ---
                Text('HARGA SATUAN (MODAL)', style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1)),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController, 
                  keyboardType: TextInputType.number, 
                  inputFormatters: [CurrencyInputFormatter()],
                  style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: AppPallete.primary),
                  decoration: InputDecoration(
                    hintText: 'Rp 0',
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.payments_rounded, color: AppPallete.primary),
                  ),
                ),
                const SizedBox(height: 40),

                // --- ACTIONS ---
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('BATAL', style: GoogleFonts.outfit(color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppPallete.primary,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          final qty = double.tryParse(qtyController.text);
                          // Clean the currency string before parsing
                          final priceStr = priceController.text.replaceAll(RegExp(r'[^0-9]'), '');
                          final price = int.tryParse(priceStr);
                          
                          if (qty == null || price == null) {
                            showSnackbar(context, 'Lengkapi data pengadaan dengan benar.');
                            return;
                          }

                          setState(() {
                            if (existing != -1) _selectedItems.removeAt(existing);
                            _selectedItems.add({
                              'stock_id': stock.id,
                              'name': stock.itemName,
                              'quantity': qty,
                              'price_per_unit': price,
                            });
                          });
                          Navigator.pop(context);
                        },
                        child: Text('SIMPAN ITEM', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
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

  void _submitPO() {
    if (_supplierController.text.isEmpty || _selectedItems.isEmpty) {
      showSnackbar(context, 'Lengkapi data vendor dan item pengadaan.');
      return;
    }

    context.read<InventoryBloc>().add(CreatePurchaseOrderEvent(
      supplierName: _supplierController.text,
      items: _selectedItems,
    ));
  }
}
