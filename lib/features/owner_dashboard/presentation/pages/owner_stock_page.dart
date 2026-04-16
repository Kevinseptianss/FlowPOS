import 'dart:ui';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/show_snackbar.dart';
import 'package:flow_pos/features/inventory/domain/entities/stock.dart';
import 'package:flow_pos/features/inventory/presentation/bloc/inventory_bloc.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_purchase_order_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_stock_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class OwnerStockPage extends StatefulWidget {
  const OwnerStockPage({super.key});

  @override
  State<OwnerStockPage> createState() => _OwnerStockPageState();
}

class _OwnerStockPageState extends State<OwnerStockPage> {
  @override
  void initState() {
    super.initState();
    context.read<InventoryBloc>().add(GetStockLevelsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<InventoryBloc, InventoryState>(
      listener: (context, state) {
        if (state is InventoryFailure) {
          showSnackbar(context, state.message);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFB),
          resizeToAvoidBottomInset: false,
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;

              return Stack(
                children: [
                  // --- BACKGROUND ACCENT ---
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        color: AppPallete.primary.withAlpha(50),
                        shape: BoxShape.circle,
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                  ),

                  RefreshIndicator(
                    onRefresh: () async {
                      context.read<InventoryBloc>().add(GetStockLevelsEvent());
                    },
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        _buildSliverHeader(context, isMobile, state),
                        if (state is InventoryLoaded)
                          _buildStockSliverList(
                            // APPLY FILTER HERE: Only show items that have been ordered before (via PO)
                            // or have current stock.
                            state.stocks
                                .where(
                                  (s) => s.hasPurchaseOrder || s.quantity > 0,
                                )
                                .toList(),
                            isMobile,
                          )
                        else
                          const SliverFillRemaining(
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        const SliverToBoxAdapter(child: SizedBox(height: 120)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: _buildPremiumFAB(context),
        );
      },
    );
  }

  Widget _buildSliverHeader(
    BuildContext context,
    bool isMobile,
    InventoryState state,
  ) {
    return SliverToBoxAdapter(
      child: Container(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 32,
          (isMobile ? 16 : 32) + MediaQuery.of(context).padding.top,
          isMobile ? 16 : 32,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pusat Inventori',
                      style: GoogleFonts.outfit(
                        fontSize: isMobile ? 28 : 36,
                        fontWeight: FontWeight.w800,
                        color: AppPallete.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      'Pusat kendali stok dan logistik.',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppPallete.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                if (!isMobile) _buildSearchField(300),
              ],
            ),
            const SizedBox(height: 32),
            if (isMobile) ...[
              _buildSearchField(double.infinity),
              const SizedBox(height: 24),
            ],
            if (state is InventoryLoaded)
              _buildMainMetrics(state.stocks, isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(double width) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        style: GoogleFonts.outfit(
          color: AppPallete.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Cari inventori...',
          hintStyle: GoogleFonts.outfit(
            fontSize: 14,
            color: AppPallete.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppPallete.primary,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildMainMetrics(List<Stock> stocks, bool isMobile) {
    final lowStock = stocks
        .where((s) => s.quantity <= s.minThreshold && s.quantity > 0)
        .length;
    final outOfStock = stocks.where((s) => s.quantity <= 0).length;

    return Row(
      children: [
        _buildMetricOrb(
          'Active Item',
          stocks.length.toString(),
          Icons.layers_rounded,
          Colors.blue,
        ),
        const SizedBox(width: 12),
        _buildMetricOrb(
          'Low Stock',
          lowStock.toString(),
          Icons.auto_graph_rounded,
          Colors.orange,
        ),
        const SizedBox(width: 12),
        _buildMetricOrb(
          'Critical',
          outOfStock.toString(),
          Icons.emergency_rounded,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildMetricOrb(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withAlpha(200), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(80),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(icon, size: 60, color: Colors.white.withAlpha(30)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withAlpha(200),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockSliverList(List<Stock> stocks, bool isMobile) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final stock = stocks[index];
          final divisor = stock.minThreshold <= 0
              ? 15
              : (stock.minThreshold * 3);
          final percent = (stock.quantity / divisor).clamp(0.0, 1.0).toDouble();
          final statusColor = stock.quantity <= 0
              ? Colors.red
              : (stock.quantity <= stock.minThreshold
                    ? Colors.orange
                    : Colors.green);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    OwnerStockDetailPage.route(stock),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppPallete.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                color: AppPallete.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stock.itemName,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppPallete.textPrimary,
                                    ),
                                  ),
                                  if (stock.variantName != null)
                                    Text(
                                      stock.variantName!,
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: AppPallete.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${stock.quantity.toInt()} Unit',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                ),
                                Text(
                                  stock.quantity <= 0
                                      ? 'Out of Stock'
                                      : (stock.quantity <= stock.minThreshold
                                            ? 'Running Low'
                                            : 'Healthy'),
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: statusColor.withAlpha(150),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // --- STOCK HEALTH BAR ---
                        Stack(
                          children: [
                            Container(
                              height: 6,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppPallete.divider,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: percent,
                              child: Container(
                                height: 6,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      statusColor.withAlpha(150),
                                      statusColor,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor.withAlpha(100),
                                      blurRadius: 4,
                                    ),
                                  ],
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
            ),
          );
        }, childCount: stocks.length),
      ),
    );
  }

  Widget _buildPremiumFAB(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppPallete.primary.withAlpha(80),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 90),
      child: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.push(context, OwnerPurchaseOrderPage.route()),
        backgroundColor: AppPallete.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
        label: Text(
          'BUAT PO',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
