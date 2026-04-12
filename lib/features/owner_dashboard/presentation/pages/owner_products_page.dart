import 'package:flow_pos/core/theme/app_pallete.dart';
import 'package:flow_pos/core/utils/format_rupiah.dart';
import 'package:flow_pos/features/category/presentation/bloc/category_bloc.dart';
import 'package:flow_pos/features/menu_item/presentation/bloc/menu_item_bloc.dart';
import 'package:flow_pos/features/menu_item/domain/entities/menu_item.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_product_edit_page.dart';
import 'package:flow_pos/features/owner_dashboard/presentation/pages/owner_product_create_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    // Load initial data
    _fetchData();
  }

  void _fetchData() {
    context.read<MenuItemBloc>().add(GetAllMenuItemsEvent());
    context.read<CategoryBloc>().add(GetAllCategoriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPallete.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            _buildSearchAndFilter(context),
            Expanded(
              child: _buildProductList(context),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, OwnerProductCreatePage.route()).then((_) {
            _fetchData(); // Refresh list after returning
          });
        },
        backgroundColor: AppPallete.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Produk',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manajemen Produk',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppPallete.primary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kelola daftar menu dan kategori anda',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppPallete.textSecondary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                prefixIcon: const Icon(Icons.search, color: AppPallete.primary),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Category Chips
        BlocBuilder<CategoryBloc, CategoryState>(
          builder: (context, state) {
            final categories = <Map<String, String>>[
              {'id': 'all', 'name': 'Semua'}
            ];

            if (state is CategoryLoaded) {
              for (var cat in state.categories) {
                categories.add({'id': cat.id, 'name': cat.name});
              }
            }

            return SizedBox(
              height: 50,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _selectedCategoryId == cat['id'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(cat['name']!),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategoryId = cat['id']!);
                        }
                      },
                      selectedColor: AppPallete.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppPallete.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: isSelected ? AppPallete.primary : AppPallete.divider,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildProductList(BuildContext context) {
    return BlocBuilder<MenuItemBloc, MenuItemState>(
      builder: (context, state) {
        if (state is MenuItemLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is MenuItemLoaded) {
          final filteredItems = state.menuItems.where((item) {
            final matchesSearch =
                item.name.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesCategory = _selectedCategoryId == 'all' ||
                item.category.id == _selectedCategoryId;
            return matchesSearch && matchesCategory;
          }).toList();

          if (filteredItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: AppPallete.divider),
                  const SizedBox(height: 16),
                  Text(
                    'Produk tidak ditemukan',
                    style: TextStyle(color: AppPallete.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final product = filteredItems[index];
              return _buildProductCard(context, product);
            },
          );
        }

        if (state is MenuItemFailure) {
          return Center(child: Text(state.message));
        }

        return const Center(child: Text('Memuat menu...'));
      },
    );
  }

  Widget _buildProductCard(BuildContext context, MenuItem product) {
    return InkWell(
      onTap: () {
        // Navigate directly to edit page
        Navigator.push(
          context,
          OwnerProductEditPage.route(product),
        ).then((_) {
          _fetchData();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image Placeholder
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppPallete.primary.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.fastfood, color: AppPallete.primary),
            ),
            const SizedBox(width: 16),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppPallete.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.category.name,
                    style: TextStyle(
                      color: AppPallete.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatRupiah(product.price),
                    style: const TextStyle(
                      color: AppPallete.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Status Badge
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: product.enabled
                        ? AppPallete.success.withAlpha(20)
                        : AppPallete.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    product.enabled ? 'Tersedia' : 'Habis',
                    style: TextStyle(
                      color: product.enabled ? AppPallete.success : AppPallete.error,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(Icons.chevron_right, color: AppPallete.divider),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
