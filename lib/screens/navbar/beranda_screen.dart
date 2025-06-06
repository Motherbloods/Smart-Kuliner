import 'package:flutter/material.dart';
import 'package:smart/utils/searchable.dart';
import 'package:smart/widgets/product_card.dart';
import "../../dummy/produk.dart";

class BerandaScreen extends StatefulWidget implements Searchable {
  BerandaScreen({Key? key}) : super(key: key);

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();

  @override
  void onSearch(String query) {
    print('🔍 Menerima query pencarian: $query');
    // Implementasi akan di-handle oleh State
    if (_state != null) {
      print('🔍 Memanggil _performSearch di state');
      _state!._performSearch(query);
    } else {
      print('🔍 ERROR: _state is null!');
    }
  }

  _BerandaScreenState? _state;
}

class _BerandaScreenState extends State<BerandaScreen> {
  String _activeSearchQuery = '';
  bool _isSearchActive = false;

  // Dummy data produk kuliner
  final List<Map<String, dynamic>> _products = produk;
  final List<String> _categories = categories;
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    // Set reference ke state di widget
    widget._state = this;
    print('🔍 BerandaScreen initState - _state di-set');
  }

  @override
  void dispose() {
    // Clear reference
    widget._state = null;
    print('🔍 BerandaScreen dispose - _state di-clear');
    super.dispose();
  }

  // Method untuk perform search (saat tombol search diklik)
  void _performSearch(String query) {
    print('🔍 Melakukan pencarian untuk: $query');
    if (mounted) {
      // Fixed: was !mounted
      setState(() {
        _activeSearchQuery = query.trim();
        _isSearchActive = query.trim().isNotEmpty;
      });
      print(
        '🔍 Search berhasil di-set: $_activeSearchQuery, isActive: $_isSearchActive',
      );
    } else {
      print('🔍 ERROR: Widget not mounted!');
    }
  }

  List<Map<String, dynamic>> get _filteredProducts {
    return _products.where((product) {
      final matchesSearch =
          !_isSearchActive ||
          _activeSearchQuery.isEmpty ||
          product['name'].toString().toLowerCase().contains(
            _activeSearchQuery.toLowerCase(),
          ) ||
          product['description'].toString().toLowerCase().contains(
            _activeSearchQuery.toLowerCase(),
          ) ||
          product['restaurant'].toString().toLowerCase().contains(
            _activeSearchQuery.toLowerCase(),
          );

      final matchesCategory =
          _selectedCategory == 'Semua' ||
          product['category'] == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Categories
          SliverToBoxAdapter(
            child: Container(
              height: 50,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      margin: EdgeInsets.only(
                        right: index == _categories.length - 1 ? 0 : 12,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFFF6B35)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF6B35)
                              : Colors.grey.shade300,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFFFF6B35,
                                  ).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey[600],
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // Products Grid
          _filteredProducts.isEmpty
              ? SliverToBoxAdapter(
                  child: Container(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🔍', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          Text(
                            _isSearchActive && _activeSearchQuery.isNotEmpty
                                ? 'Produk tidak ditemukan'
                                : 'Tidak ada produk',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isSearchActive && _activeSearchQuery.isNotEmpty
                                ? 'Coba kata kunci lain atau ubah kategori'
                                : 'Belum ada produk yang tersedia',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final product = _filteredProducts[index];
                      return ProductCard(product: product);
                    }, childCount: _filteredProducts.length),
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}
