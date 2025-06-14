// product_grid_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart'; // jika pakai sliver
import 'package:smart/widgets/product_card.dart';

class ProductGridWidget extends StatelessWidget {
  final bool isLoading;
  final List<dynamic>
  filteredProducts; // Ganti `dynamic` dengan tipe model kamu

  const ProductGridWidget({
    Key? key,
    required this.isLoading,
    required this.filteredProducts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(50),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    if (filteredProducts.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(50),
            child: Column(
              children: [
                Icon(Icons.search_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Tidak ada produk ditemukan',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = filteredProducts[index];
          return ProductCard(product: product);
        }, childCount: filteredProducts.length),
      ),
    );
  }
}
