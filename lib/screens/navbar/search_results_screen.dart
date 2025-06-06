import 'package:flutter/material.dart';
import 'package:smart/widgets/product_card.dart';
import '../../dummy/produk.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;

  const SearchResultsScreen({Key? key, required this.query}) : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final List<Map<String, dynamic>> _products = produk;
  final List<String> _categories = categories;
  String _selectedCategory = 'Semua';
  double _minPrice = 0;
  double _maxPrice = 50000;
  double _minRating = 0;
  bool _showFilters = false;
  String _sortBy =
      'Terbaru'; // Terbaru, Harga Terendah, Harga Tertinggi, Rating Tertinggi

  final List<String> _sortOptions = [
    'Terbaru',
    'Harga Terendah',
    'Harga Tertinggi',
    'Rating Tertinggi',
  ];

  @override
  void initState() {
    super.initState();
    // Set max price berdasarkan produk termahal
    _maxPrice = _products
        .map((p) => p['price'].toDouble())
        .reduce((a, b) => a > b ? a : b);
    print("INIT STATE QUERY: ${widget.query}");
  }

  List<Map<String, dynamic>> get _filteredProducts {
    print("widget.query ${widget.query}");
    var filtered = _products.where((product) {
      // Search filter
      final matchesSearch =
          widget.query.isEmpty ||
          product['name'].toString().toLowerCase().contains(
            widget.query.toLowerCase(),
          ) ||
          product['description'].toString().toLowerCase().contains(
            widget.query.toLowerCase(),
          ) ||
          product['restaurant'].toString().toLowerCase().contains(
            widget.query.toLowerCase(),
          );

      // Category filter
      final matchesCategory =
          _selectedCategory == 'Semua' ||
          product['category'] == _selectedCategory;

      // Price filter
      final price = product['price'].toDouble();
      final matchesPrice = price >= _minPrice && price <= _maxPrice;

      // Rating filter
      final rating = product['rating'].toDouble();
      final matchesRating = rating >= _minRating;

      return matchesSearch && matchesCategory && matchesPrice && matchesRating;
    }).toList();

    // Sort results
    switch (_sortBy) {
      case 'Harga Terendah':
        filtered.sort((a, b) => a['price'].compareTo(b['price']));
        break;
      case 'Harga Tertinggi':
        filtered.sort((a, b) => b['price'].compareTo(a['price']));
        break;
      case 'Rating Tertinggi':
        filtered.sort((a, b) => b['rating'].compareTo(a['rating']));
        break;
      default: // Terbaru
        break;
    }

    return filtered;
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'Semua';
      _minPrice = 0;
      _maxPrice = _products
          .map((p) => p['price'].toDouble())
          .reduce((a, b) => a > b ? a : b);
      _minRating = 0;
      _sortBy = 'Terbaru';
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _filteredProducts;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hasil Pencarian',
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '"${widget.query}" - ${filteredProducts.length} produk',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
              color: const Color(0xFFFF6B35),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? null : 0,
            child: _showFilters ? _buildFiltersSection() : null,
          ),

          // Sort and Results Count
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredProducts.length} produk ditemukan',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                GestureDetector(
                  onTap: _showSortOptions,
                  child: Row(
                    children: [
                      Icon(Icons.sort, size: 18, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _sortBy,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: filteredProducts.isEmpty
                ? _buildEmptyState()
                : _buildProductGrid(filteredProducts),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: const Text(
                  'Reset',
                  style: TextStyle(color: Color(0xFFFF6B35)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Category Filter
          const Text(
            'Kategori',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
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
                      right: index == _categories.length - 1 ? 0 : 8,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFFF6B35)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Price Range Filter
          const Text(
            'Range Harga',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          RangeSlider(
            values: RangeValues(_minPrice, _maxPrice),
            min: 0,
            max: _products
                .map((p) => p['price'].toDouble())
                .reduce((a, b) => a > b ? a : b),
            divisions: 10,
            activeColor: const Color(0xFFFF6B35),
            labels: RangeLabels(
              'Rp ${_minPrice.toInt()}',
              'Rp ${_maxPrice.toInt()}',
            ),
            onChanged: (values) {
              setState(() {
                _minPrice = values.start;
                _maxPrice = values.end;
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rp ${_minPrice.toInt()}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              Text(
                'Rp ${_maxPrice.toInt()}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating Filter
          const Text(
            'Rating Minimum',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Slider(
            value: _minRating,
            min: 0,
            max: 5,
            divisions: 5,
            activeColor: const Color(0xFFFF6B35),
            label: '${_minRating.toStringAsFixed(1)} ⭐',
            onChanged: (value) {
              setState(() {
                _minRating = value;
              });
            },
          ),
          Text(
            'Rating minimal: ${_minRating.toStringAsFixed(1)} ⭐',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🔍', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada produk ditemukan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah kata kunci atau filter pencarian',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _resetFilters,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Reset Filter',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(List<Map<String, dynamic>> products) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return ProductCard(product: product);
        },
      ),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Urutkan berdasarkan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ...(_sortOptions.map((option) {
                return ListTile(
                  title: Text(option),
                  trailing: _sortBy == option
                      ? const Icon(Icons.check, color: Color(0xFFFF6B35))
                      : null,
                  onTap: () {
                    setState(() {
                      _sortBy = option;
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList()),
            ],
          ),
        );
      },
    );
  }
}
