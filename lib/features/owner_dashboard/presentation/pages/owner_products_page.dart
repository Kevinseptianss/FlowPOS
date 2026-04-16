import 'dart:ui';
import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flow_pos/features/menu_item/presentation/bloc/menu_item_bloc.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_product_edit_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_product_create_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

class OwnerProductsPage extends StatefulWidget {
  const OwnerProductsPage({super.key});

  @override
  State<OwnerProductsPage> createState() => _OwnerProductsPageState();
}

class _OwnerProductsPageState extends State<OwnerProductsPage> {
  String _searchQuery = '';
  String _selectedCategoryId = 'all';

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() {
    context.read<MenuItemBloc>().add(GetAllMenuItemsEvent());
    context.read<CategoryBloc>().add(GetAllCategoriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          final topPadding = MediaQuery.of(context).padding.top;

          return Stack(
            children: [
              // --- PREMIUM BACKGROUND BLUR ---
              Positioned(
                top: -100,
                right: -100,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    color: AppPallete.primary.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    child: Container(color: Colors.transparent),
                  ),
                ),
              ),

              RefreshIndicator(
                onRefresh: () async => _fetchData(),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverHeader(context, isMobile, topPadding),
                    _buildSearchAndFilterSliver(isMobile),
                    _buildProductSliverList(isMobile),
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
  }

  Widget _buildSliverHeader(
    BuildContext context,
    bool isMobile,
    double topPadding,
  ) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 16 : 32,
          (isMobile ? 16 : 32) + topPadding,
          isMobile ? 16 : 32,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manajemen Produk',
              style: GoogleFonts.outfit(
                fontSize: isMobile ? 28 : 36,
                fontWeight: FontWeight.w800,
                color: AppPallete.textPrimary,
                letterSpacing: -1,
              ),
            ),
            Text(
              'Kelola katalog menu dan ketersediaan.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppPallete.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),
            _buildMetricsRow(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow(bool isMobile) {
    return BlocBuilder<MenuItemBloc, MenuItemState>(
      builder: (context, state) {
        if (state is MenuItemLoaded) {
          final total = state.menuItems.length;
          final active = state.menuItems.where((i) => i.enabled).length;
          final inactive = total - active;

          return Row(
            children: [
              _buildMetricOrb(
                'Total Menu',
                total.toString(),
                Icons.restaurant_menu_rounded,
                Colors.blue,
              ),
              const SizedBox(width: 12),
              _buildMetricOrb(
                'Tersedia',
                active.toString(),
                Icons.check_circle_rounded,
                Colors.green,
              ),
              const SizedBox(width: 12),
              _buildMetricOrb(
                'Habis',
                inactive.toString(),
                Icons.cancel_rounded,
                Colors.red,
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
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
        height: 90,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withAlpha(190), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(60),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -5,
              bottom: -5,
              child: Icon(icon, size: 44, color: Colors.white.withAlpha(40)),
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
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
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

  Widget _buildSearchAndFilterSliver(bool isMobile) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 32),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 20),
                ],
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: AppPallete.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Cari produk...',
                  hintStyle: GoogleFonts.outfit(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppPallete.primary,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildCategoryFilterList(isMobile),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterList(bool isMobile) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        final categories = <Map<String, String>>[
          {'id': 'all', 'name': 'Semua'},
        ];
        if (state is CategoryLoaded) {
          for (var cat in state.categories) {
            categories.add({'id': cat.id, 'name': cat.name});
          }
        }

        return SizedBox(
          height: 44,
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 32),
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
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (selected) =>
                      setState(() => _selectedCategoryId = cat['id']!),
                  selectedColor: AppPallete.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppPallete.textPrimary,
                  ),
                  backgroundColor: Colors.white,
                  showCheckmark: false,
                  elevation: isSelected ? 4 : 0,
                  shadowColor: AppPallete.primary.withAlpha(80),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected
                          ? AppPallete.primary
                          : Colors.grey[200]!,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductSliverList(bool isMobile) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 20 : 32),
      sliver: BlocBuilder<MenuItemBloc, MenuItemState>(
        builder: (context, state) {
          if (state is MenuItemLoaded) {
            final filtered = state.menuItems.where((item) {
              final matchesSearch = item.name.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              );
              final matchesCategory =
                  _selectedCategoryId == 'all' ||
                  item.category.id == _selectedCategoryId;
              return matchesSearch && matchesCategory;
            }).toList();

            return filtered.isEmpty
                ? const SliverToBoxAdapter(
                    child: Center(child: Text('Produk tidak ditemukan')),
                  )
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildProductCard(context, filtered[index]),
                      childCount: filtered.length,
                    ),
                  );
          }
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, MenuItem product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 15,
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
              OwnerProductEditPage.route(product),
            ).then((_) => _fetchData()),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppPallete.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.fastfood_rounded,
                      color: AppPallete.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: AppPallete.textPrimary,
                          ),
                        ),
                        Text(
                          product.category.name,
                          style: GoogleFonts.outfit(
                            color: AppPallete.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatRupiah(product.price),
                          style: GoogleFonts.outfit(
                            color: AppPallete.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(product.enabled),
                  const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool enabled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: enabled
            ? AppPallete.success.withAlpha(20)
            : AppPallete.error.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        enabled ? 'Tersedia' : 'Habis',
        style: GoogleFonts.outfit(
          color: enabled ? AppPallete.success : AppPallete.error,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
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
        onPressed: () => Navigator.push(
          context,
          OwnerProductCreatePage.route(),
        ).then((_) => _fetchData()),
        backgroundColor: AppPallete.primary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'TAMBAH PRODUK',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}
