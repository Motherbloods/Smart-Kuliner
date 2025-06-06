// beranda_screen.dart - Updated version
import 'package:flutter/material.dart';
import 'package:smart/utils/searchable.dart';
import 'package:smart/widgets/product_card.dart';
import 'package:smart/models/product.dart';
import 'package:smart/services/product_service.dart';

class BerandaScreen extends StatefulWidget implements Searchable {
  BerandaScreen({Key? key}) : super(key: key);

  @override
  State<BerandaScreen> createState() => _BerandaScreenState();

  @override
  void onSearch(String query) {
    print('🔍 Menerima query pencarian: $query');
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
  final ProductService _productService = ProductService();

  String _activeSearchQuery = '';
  bool _isSearchActive = false;
  bool _isLoading = true;
  String? _error;

  // Data produk dari Firebase
  List<ProductModel> _allProducts = [];

  // Categories
  final List<String> _categories = [
    'Semua',
    'Makanan Utama',
    'Cemilan',
    'Minuman',
    'Makanan Sehat',
  ];
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    widget._state = this;
    _loadProducts();
    print('🔍 BerandaScreen initState - _state di-set');
  }

  @override
  void dispose() {
    widget._state = null;
    print('🔍 BerandaScreen dispose - _state di-clear');
    super.dispose();
  }

  // Load products from Firebase
  void _loadProducts() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    // Listen to all active products
    _productService.getAllActiveProducts().listen(
      (products) {
        if (mounted) {
          setState(() {
            _allProducts = products;
            _isLoading = false;
            _error = null;
          });
          print('✅ Loaded ${products.length} products from Firebase');
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _error = 'Gagal memuat produk: $error';
          });
          print('❌ Error loading products: $error');
        }
      },
    );
  }

  // Method untuk perform search
  void _performSearch(String query) {
    print('🔍 Melakukan pencarian untuk: $query');
    if (mounted) {
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

  // Filter products based on search and category
  List<ProductModel> get _filteredProducts {
    return _allProducts.where((product) {
      final matchesSearch =
          !_isSearchActive ||
          _activeSearchQuery.isEmpty ||
          product.name.toLowerCase().contains(
            _activeSearchQuery.toLowerCase(),
          ) ||
          product.description.toLowerCase().contains(
            _activeSearchQuery.toLowerCase(),
          );
      final matchesCategory =
          _selectedCategory == 'Semua' || product.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Refresh products
  void _refreshProducts() {
    _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshProducts();
        },
        child: CustomScrollView(
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
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey[600],
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

            // Loading State
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(color: Color(0xFFFF6B35)),
                  ),
                ),
              ),

            // Error State
            if (_error != null && !_isLoading)
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade400,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshProducts,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B35),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              ),

            // Empty State
            if (_filteredProducts.isEmpty && !_isLoading && _error == null)
              SliverToBoxAdapter(
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
                              : 'Belum ada produk',
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
                              : 'Produk akan muncul di sini',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Products Grid
            if (_filteredProducts.isNotEmpty && !_isLoading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
      ),
    );
  }
}
