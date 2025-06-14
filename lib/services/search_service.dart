import 'package:smart/models/product.dart';
import 'package:smart/models/edukasi.dart';
import 'package:smart/models/search_filter_model.dart';
import 'package:smart/models/seller.dart';
import 'package:smart/services/product_service.dart';
import 'package:smart/services/edukasi_service.dart';

class SearchService {
  final ProductService _productService = ProductService();
  final EdukasiService _edukasiService = EdukasiService();

  // Categories yang sama untuk produk dan edukasi
  static const List<String> categories = [
    'Semua',
    'Makanan Utama',
    'Cemilan',
    'Minuman',
    'Makanan Sehat',
    'Dessert',
    'Lainnya',
  ];

  static const List<String> sortOptions = [
    'Terbaru',
    'Harga Terendah',
    'Harga Tertinggi',
    'Rating Tertinggi',
    'Paling Populer',
  ];

  static const List<String> resultTypeOptions = [
    'Semua',
    'Produk',
    'Edukasi',
    "Seller",
  ];

  // Get products stream
  Stream<List<ProductModel>> getProducts() {
    return _productService.getAllActiveProducts();
  }

  // Get edukasi stream
  Stream<List<EdukasiModel>> getEdukasi() {
    print('ini kepanggil');
    return Stream.fromFuture(_edukasiService.getPublishedEdukasi());
  }

  // Filter products
  List<ProductModel> filterProducts(
    List<ProductModel> products,
    String query,
    SearchFilterModel filter,
  ) {
    var filtered = products.where((product) {
      // Search filter
      final matchesSearch =
          query.isEmpty ||
          product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.description.toLowerCase().contains(query.toLowerCase());

      // Category filter
      final matchesCategory =
          filter.selectedCategory == 'Semua' ||
          product.category == filter.selectedCategory;

      // Price filter
      final matchesPrice =
          product.price >= filter.minPrice && product.price <= filter.maxPrice;

      // Rating filter
      final matchesRating = product.rating >= filter.minRating;

      return matchesSearch && matchesCategory && matchesPrice && matchesRating;
    }).toList();

    return _sortProducts(filtered, filter.sortBy);
  }

  // Filter edukasi
  List<EdukasiModel> filterEdukasi(
    List<EdukasiModel> edukasiList,
    String query,
    SearchFilterModel filter,
  ) {
    var filtered = edukasiList.where((edukasi) {
      // Search filter
      final matchesSearch =
          query.isEmpty ||
          edukasi.title.toLowerCase().contains(query.toLowerCase()) ||
          edukasi.description.toLowerCase().contains(query.toLowerCase()) ||
          edukasi.namaToko.toLowerCase().contains(query.toLowerCase()) ||
          edukasi.category.toLowerCase().contains(query.toLowerCase()) ||
          (edukasi.tags != null &&
              edukasi.tags!.any(
                (tag) => tag.toLowerCase().contains(query.toLowerCase()),
              ));

      // Category filter
      final matchesCategory =
          filter.selectedCategory == 'Semua' ||
          edukasi.category == filter.selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    return _sortEdukasi(filtered, filter.sortBy);
  }

  static List<SellerModel> filterSellers(
    List<SellerModel> sellers,
    String query,
    SearchFilterModel filter,
  ) {
    var filtered = sellers.where((seller) {
      // Search filter
      final matchesSearch =
          query.isEmpty ||
          seller.nameToko.toLowerCase().contains(query.toLowerCase()) ||
          seller.description.toLowerCase().contains(query.toLowerCase()) ||
          seller.location.toLowerCase().contains(query.toLowerCase()) ||
          seller.tags.any(
            (tag) => tag.toLowerCase().contains(query.toLowerCase()),
          );

      // Category filter
      final matchesCategory =
          filter.selectedCategory == 'Semua' ||
          seller.category == filter.selectedCategory;

      // Rating filter
      final matchesRating = seller.rating >= filter.minRating;

      // Verified filter
      final matchesVerified = !filter.onlyVerifiedSellers || seller.isVerified;

      return matchesSearch &&
          matchesCategory &&
          matchesRating &&
          matchesVerified;
    }).toList();

    // Sort results
    return _sortSellers(filtered, filter.sortBy);
  }

  // Sort products
  List<ProductModel> _sortProducts(List<ProductModel> products, String sortBy) {
    switch (sortBy) {
      case 'Harga Terendah':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'Harga Tertinggi':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'Rating Tertinggi':
        products.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default: // Terbaru
        products.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return products;
  }

  // Sort edukasi
  List<EdukasiModel> _sortEdukasi(
    List<EdukasiModel> edukasiList,
    String sortBy,
  ) {
    switch (sortBy) {
      case 'Rating Tertinggi':
        edukasiList.sort((a, b) => b.likes!.compareTo(a.likes!));
        break;
      default: // Terbaru
        edukasiList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return edukasiList;
  }

  static List<SellerModel> _sortSellers(
    List<SellerModel> sellers,
    String sortBy,
  ) {
    switch (sortBy) {
      case 'Rating Tertinggi':
        sellers.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case 'Paling Populer':
        sellers.sort((a, b) => b.totalProducts.compareTo(a.totalProducts));
        break;
      default: // Terbaru
        sellers.sort((a, b) => b.joinedDate.compareTo(a.joinedDate));
        break;
    }
    return sellers;
  }

  // Get max price from products
  double getMaxPrice(List<ProductModel> products) {
    if (products.isEmpty) return 100000;
    return products.map((p) => p.price).reduce((a, b) => a > b ? a : b);
  }
}
