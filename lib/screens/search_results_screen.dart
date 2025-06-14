import 'package:flutter/material.dart';
import 'package:smart/models/product.dart';
import 'package:smart/models/edukasi.dart';
import 'package:smart/models/seller.dart';
import 'package:smart/models/search_filter_model.dart';
import 'package:smart/services/search_service.dart';
import 'package:smart/services/seller_service.dart';
import 'package:smart/widgets/search_filter_widget.dart';
import 'package:smart/widgets/search_result_type.dart';
import 'package:smart/widgets/search_results_grid.dart';

class SearchResultsScreen extends StatefulWidget {
  final String query;

  const SearchResultsScreen({Key? key, required this.query}) : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  final SearchService _searchService = SearchService();
  final SellerService _sellerService = SellerService();

  // Data
  List<ProductModel> _allProducts = [];
  List<EdukasiModel> _allEdukasi = [];
  List<SellerModel> _allSellers = [];

  // State
  bool _isLoading = true;
  String? _error;
  bool _showFilters = false;
  SearchFilterModel _filter = SearchFilterModel();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    int loadedCount = 0;
    const totalLoaders = 3;

    void checkComplete() {
      loadedCount++;
      if (loadedCount >= totalLoaders) {
        setState(() {
          _isLoading = false;
        });
      }
    }

    // Load products
    _searchService.getProducts().listen(
      (products) {
        if (mounted) {
          setState(() {
            _allProducts = products;
            _updateMaxPrice();
          });
          checkComplete();
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _error = 'Gagal memuat data produk: $error';
          });
          checkComplete();
        }
      },
    );

    // Load edukasi
    _searchService.getEdukasi().listen(
      (edukasiList) {
        debugPrint('ini adalah edukasi: ${edukasiList.join()}');
        if (mounted) {
          setState(() {
            _allEdukasi = edukasiList;
          });
          checkComplete();
        }
      },
      onError: (error) {
        print('Error loading edukasi: $error');
        checkComplete();
      },
    );

    // Load sellers
    _sellerService.getAllSellers().listen(
      (sellers) {
        if (mounted) {
          setState(() {
            _allSellers = sellers;
          });
          checkComplete();
        }
      },
      onError: (error) {
        print('Error loading sellers: $error');
        checkComplete();
      },
    );
  }

  void _updateMaxPrice() {
    final maxPrice = _searchService.getMaxPrice(_allProducts);
    _filter = _filter.copyWith(maxPrice: maxPrice);
  }

  List<ProductModel> get _filteredProducts {
    if (_filter.resultType == SearchResultType.edukasi ||
        _filter.resultType == SearchResultType.sellers)
      return [];
    return _searchService.filterProducts(_allProducts, widget.query, _filter);
  }

  List<EdukasiModel> get _filteredEdukasi {
    if (_filter.resultType == SearchResultType.products ||
        _filter.resultType == SearchResultType.sellers)
      return [];
    return _searchService.filterEdukasi(_allEdukasi, widget.query, _filter);
  }

  List<SellerModel> get _filteredSellers {
    if (_filter.resultType == SearchResultType.products ||
        _filter.resultType == SearchResultType.edukasi)
      return [];
    return SearchService.filterSellers(_allSellers, widget.query, _filter);
  }

  int get _totalResults {
    switch (_filter.resultType) {
      case SearchResultType.products:
        return _filteredProducts.length;
      case SearchResultType.edukasi:
        return _filteredEdukasi.length;
      case SearchResultType.sellers:
        return _filteredSellers.length;
      case SearchResultType.all:
        return _filteredProducts.length +
            _filteredEdukasi.length +
            _filteredSellers.length;
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
      '${_allSellers.isNotEmpty ? _allSellers[0] : 'List kosong'} halo ini adlaah',
    );
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Filter Section
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: _showFilters ? null : 0,
            child: _showFilters ? _buildFiltersSection() : null,
          ),

          // Sort and Results Count
          if (!_isLoading) _buildResultsHeader(),

          // Results
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back, color: Colors.black87),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hasil Pencarian',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '"${widget.query}" - ${_isLoading ? '...' : '$_totalResults hasil'}',
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
            color: const Color(0xFF4DA8DA),
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    return SearchFilterWidget(
      filter: _filter,
      maxPriceAvailable: _searchService.getMaxPrice(_allProducts),
      onFilterChanged: (newFilter) {
        setState(() {
          _filter = newFilter;
        });
      },
      onResetFilters: () {
        setState(() {
          _filter.reset();
          _updateMaxPrice();
        });
      },
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$_totalResults hasil ditemukan',
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
                  _filter.sortBy,
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
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF4DA8DA)),
            SizedBox(height: 16),
            Text(
              'Mencari...',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4DA8DA),
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    return SearchResultsGrid(
      products: _filteredProducts,
      edukasiList: _filteredEdukasi,
      sellers: _filteredSellers,
      resultType: _filter.resultType,
      onRefresh: _loadData,
    );
  }

  void _showSortOptions() {
    // Get available sort options based on result type
    List<String> availableSortOptions = _getAvailableSortOptions();

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
              ...(availableSortOptions.map((option) {
                return ListTile(
                  title: Text(option),
                  trailing: _filter.sortBy == option
                      ? const Icon(Icons.check, color: Color(0xFF4DA8DA))
                      : null,
                  onTap: () {
                    setState(() {
                      _filter = _filter.copyWith(sortBy: option);
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

  List<String> _getAvailableSortOptions() {
    switch (_filter.resultType) {
      case SearchResultType.products:
        return [
          'Terbaru',
          'Harga Terendah',
          'Harga Tertinggi',
          'Rating Tertinggi',
        ];
      case SearchResultType.edukasi:
        return ['Terbaru', 'Rating Tertinggi'];
      case SearchResultType.sellers:
        return ['Terbaru', 'Rating Tertinggi', 'Paling Populer'];
      case SearchResultType.all:
        return SearchService.sortOptions;
    }
  }
}
