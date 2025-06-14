import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart/models/seller.dart';
import 'package:smart/models/product.dart';
import 'package:smart/screens/produk/detail_product_screen.dart';
import 'package:smart/widgets/product_card.dart';
import 'package:smart/widgets/seller/product_grid_widget.dart';
import 'package:smart/widgets/seller/search_and_filter_widget.dart';
import 'package:smart/widgets/seller/seller_description_widget.dart';
import 'package:smart/widgets/seller/seller_header_widget.dart';

class SellerDetailScreen extends StatefulWidget {
  final String sellerId;

  const SellerDetailScreen({Key? key, required this.sellerId})
    : super(key: key);

  @override
  State<SellerDetailScreen> createState() => _SellerDetailScreenState();
}

class _SellerDetailScreenState extends State<SellerDetailScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  SellerModel? seller;
  List<ProductModel> allProducts = [];
  List<ProductModel> filteredProducts = [];
  bool isLoading = true;
  String selectedCategory = 'Semua';
  List<String> categories = ['Semua'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSellerData();
    _loadProducts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSellerData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('sellers')
          .doc(widget.sellerId)
          .get();

      if (doc.exists) {
        setState(() {
          seller = SellerModel.fromMap(doc.data()!, doc.id);
        });
      }
    } catch (e) {
      print('Error loading seller data: $e');
    }
  }

  Future<void> _loadProducts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('sellerId', isEqualTo: widget.sellerId)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      final products = snapshot.docs
          .map((doc) => ProductModel.fromMap(doc.data(), doc.id))
          .toList();

      // Get unique categories
      final uniqueCategories = products
          .map((product) => product.category)
          .toSet()
          .toList();

      setState(() {
        allProducts = products;
        filteredProducts = products;
        categories = ['Semua', ...uniqueCategories];
        isLoading = false;
      });
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterProducts() {
    List<ProductModel> filtered = allProducts;

    // Filter by category
    if (selectedCategory != 'Semua') {
      filtered = filtered
          .where((product) => product.category == selectedCategory)
          .toList();
    }

    // Filter by search query
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where(
            (product) =>
                product.name.toLowerCase().contains(query) ||
                product.description.toLowerCase().contains(query),
          )
          .toList();
    }

    setState(() {
      filteredProducts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.blue.shade600,
            flexibleSpace: FlexibleSpaceBar(
              background: SellerHeaderWidget(seller: seller),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            // actions: [
            //   IconButton(
            //     icon: const Icon(Icons.share, color: Colors.white),
            //     onPressed: () {
            //       // Share functionality
            //     },
            //   ),
            //   IconButton(
            //     icon: const Icon(Icons.favorite_border, color: Colors.white),
            //     onPressed: () {
            //       // Add to favorites
            //     },
            //   ),
            // ],
          ),
          SliverToBoxAdapter(child: SellerDescriptionWidget(seller: seller)),
          SliverToBoxAdapter(
            child: SearchAndFilterWidget(
              searchController: _searchController,
              categories: categories,
              selectedCategory: selectedCategory,
              onCategorySelected: (category) {
                setState(() {
                  selectedCategory = category!;
                });
                _filterProducts();
              },
              onClear: () {
                _searchController.clear();
                _filterProducts();
              },
              onSearchChanged: _filterProducts,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Produk (${filteredProducts.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {
                      // Sort options
                    },
                    icon: const Icon(Icons.sort),
                    label: const Text('Urutkan'),
                  ),
                ],
              ),
            ),
          ),
          ProductGridWidget(
            isLoading: isLoading,
            filteredProducts: filteredProducts,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}
