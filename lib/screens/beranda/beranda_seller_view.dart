// screens/beranda/beranda_seller_view.dart
import 'package:flutter/material.dart';
import 'package:smart/models/product.dart';
import 'package:smart/screens/beranda/beranda_data_manager.dart';
import 'package:smart/screens/beranda/widgets/category_filter.dart';
import 'package:smart/screens/beranda/widgets/seller_products_grid.dart';
import 'package:smart/screens/beranda/widgets/error_state_widget.dart';
import 'package:smart/screens/beranda/widgets/empty_state_widget.dart';

class BerandaSellerView extends StatelessWidget {
  final BerandaState state;
  final String activeSearchQuery;
  final bool isSearchActive;
  final VoidCallback onRefresh;
  final Function(String) onCategoryChanged;

  const BerandaSellerView({
    Key? key,
    required this.state,
    required this.activeSearchQuery,
    required this.isSearchActive,
    required this.onRefresh,
    required this.onCategoryChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Categories
        SliverToBoxAdapter(
          child: CategoryFilter(
            categories: const [
              'Semua',
              'Makanan Utama',
              'Cemilan',
              'Minuman',
              'Makanan Sehat',
              'Dessert',
              'Lainnya',
            ],
            selectedCategory: state.selectedCategory,
            onCategoryChanged: onCategoryChanged,
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // Error State
        if (state.error != null && !state.isLoading)
          SliverToBoxAdapter(
            child: ErrorStateWidget(error: state.error!, onRetry: onRefresh),
          ),

        // Empty State
        if (_getFilteredProducts().isEmpty &&
            !state.isLoading &&
            state.error == null)
          SliverToBoxAdapter(
            child: EmptyStateWidget(
              isSearchActive: isSearchActive,
              searchQuery: activeSearchQuery,
            ),
          ),

        // Seller Products Grid
        if (_getFilteredProducts().isNotEmpty && !state.isLoading)
          SliverToBoxAdapter(
            child: SellerProductsGrid(products: _getFilteredProducts()),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),
      ],
    );
  }

  List<ProductModel> _getFilteredProducts() {
    return state.sellerProducts.where((product) {
      final matchesSearch =
          !isSearchActive ||
          activeSearchQuery.isEmpty ||
          product.name.toLowerCase().contains(
            activeSearchQuery.toLowerCase(),
          ) ||
          product.description.toLowerCase().contains(
            activeSearchQuery.toLowerCase(),
          );

      final matchesCategory =
          state.selectedCategory == 'Semua' ||
          product.category == state.selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }
}
