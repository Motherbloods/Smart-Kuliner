import 'package:smart/models/product.dart';
import 'package:smart/models/edukasi.dart';
import 'package:smart/models/konten.dart';
import 'package:smart/models/recipe.dart';
import 'package:smart/models/search_filter_model.dart';
import 'package:smart/models/seller.dart';
import 'package:smart/services/konten_service.dart';
import 'package:smart/services/product_service.dart';
import 'package:smart/services/edukasi_service.dart';
import 'package:smart/services/recipe_service.dart';

class SearchService {
  final ProductService _productService = ProductService();
  final EdukasiService _edukasiService = EdukasiService();
  final KontenService _kontenService = KontenService();
  final RecipeService _recipeService = RecipeService();

  // Categories yang sama untuk produk, edukasi, konten, dan recipe
  static const List<String> categories = [
    'Semua',
    'Makanan Utama',
    'Cemilan',
    'Minuman',
    'Dessert',
    'Makanan Sehat',
    'Makanan Tradisional',
    'Lainnya',
  ];

  static const List<String> sortOptions = [
    'Terbaru',
    'Harga Terendah',
    'Harga Tertinggi',
    'Rating Tertinggi',
    'Paling Populer',
    'Waktu Tercepat',
    'Difficulty Terendah',
  ];

  static const List<String> resultTypeOptions = [
    'Semua',
    'Produk',
    'Edukasi',
    'Konten',
    'Recipe',
    'Seller',
  ];

  // Get products stream
  Stream<List<ProductModel>> getProducts() {
    return _productService.getAllActiveProducts();
  }

  // Get edukasi stream
  Stream<List<EdukasiModel>> getEdukasi() {
    print('Loading edukasi...');
    return Stream.fromFuture(_edukasiService.getPublishedEdukasi());
  }

  // Get konten stream
  Stream<List<KontenModel>> getKonten() {
    print('Loading konten...');
    return Stream.fromFuture(_kontenService.getPublishedKonten());
  }

  // Get recipe stream
  Stream<List<CookingRecipe>> getRecipe() {
    print('Loading recipes...');
    return _recipeService.getAllActiveRecipes();
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

  // Filter konten
  List<KontenModel> filterKonten(
    List<KontenModel> kontenList,
    String query,
    SearchFilterModel filter,
  ) {
    var filtered = kontenList.where((konten) {
      // Search filter
      final matchesSearch =
          query.isEmpty ||
          konten.title.toLowerCase().contains(query.toLowerCase()) ||
          konten.description.toLowerCase().contains(query.toLowerCase()) ||
          konten.namaToko.toLowerCase().contains(query.toLowerCase()) ||
          konten.category.toLowerCase().contains(query.toLowerCase());

      // Category filter
      final matchesCategory =
          filter.selectedCategory == 'Semua' ||
          konten.category == filter.selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    return _sortKonten(filtered, filter.sortBy);
  }

  // Filter sellers
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
        edukasiList.sort((a, b) => (b.likes ?? 0).compareTo(a.likes ?? 0));
        break;
      case 'Paling Populer':
        // Asumsi: popularity berdasarkan views atau likes
        edukasiList.sort((a, b) => (b.views ?? 0).compareTo(a.views ?? 0));
        break;
      default: // Terbaru
        edukasiList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return edukasiList;
  }

  // Sort konten
  List<KontenModel> _sortKonten(List<KontenModel> kontenList, String sortBy) {
    switch (sortBy) {
      case 'Rating Tertinggi':
        kontenList.sort((a, b) => (b.likes ?? 0).compareTo(a.likes ?? 0));
        break;
      case 'Paling Populer':
        // Asumsi: popularity berdasarkan views atau likes
        kontenList.sort((a, b) => (b.views ?? 0).compareTo(a.views ?? 0));
        break;
      default: // Terbaru
        kontenList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }
    return kontenList;
  }

  // Sort sellers
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

  // Utility method untuk mendapatkan total hasil berdasarkan tipe
  int getTotalResults(
    List<ProductModel> products,
    List<EdukasiModel> edukasiList,
    List<KontenModel> kontenList,
    List<CookingRecipe> recipes,
    List<SellerModel> sellers,
    String resultType,
  ) {
    switch (resultType.toLowerCase()) {
      case 'produk':
        return products.length;
      case 'edukasi':
        return edukasiList.length;
      case 'konten':
        return kontenList.length;
      case 'recipe':
        return recipes.length;
      case 'seller':
        return sellers.length;
      default: // 'semua'
        return products.length +
            edukasiList.length +
            kontenList.length +
            recipes.length +
            sellers.length;
    }
  }

  // Method untuk mendapatkan available sort options berdasarkan result type
  List<String> getAvailableSortOptions(String resultType) {
    switch (resultType.toLowerCase()) {
      case 'produk':
        return [
          'Terbaru',
          'Harga Terendah',
          'Harga Tertinggi',
          'Rating Tertinggi',
          'Paling Populer',
        ];
      case 'edukasi':
      case 'konten':
        return ['Terbaru', 'Rating Tertinggi', 'Paling Populer'];
      case 'recipe':
        return [
          'Terbaru',
          'Rating Tertinggi',
          'Paling Populer',
          'Waktu Tercepat',
          'Difficulty Terendah',
        ];
      case 'seller':
        return ['Terbaru', 'Rating Tertinggi', 'Paling Populer'];
      default: // 'semua'
        return sortOptions;
    }
  }

  List<CookingRecipe> filterRecipes(
    List<CookingRecipe> recipes,
    String query,
    SearchFilterModel filter,
  ) {
    var filtered = recipes.where((recipe) {
      // Search filter
      final matchesSearch =
          query.isEmpty ||
          recipe.title.toLowerCase().contains(query.toLowerCase()) ||
          recipe.description.toLowerCase().contains(query.toLowerCase()) ||
          recipe.category.toLowerCase().contains(query.toLowerCase()) ||
          recipe.ingredients.any(
            (ingredient) =>
                ingredient.toLowerCase().contains(query.toLowerCase()),
          );

      // Category filter
      final matchesCategory =
          filter.selectedCategory == 'Semua' ||
          recipe.category == filter.selectedCategory;

      // Difficulty filter (if you want to add difficulty filtering)
      // You can add this to SearchFilterModel if needed
      // final matchesDifficulty = filter.maxDifficulty == null ||
      //     recipe.difficulty <= filter.maxDifficulty;

      return matchesSearch && matchesCategory;
    }).toList();

    return _sortRecipes(filtered, filter.sortBy);
  }

  List<CookingRecipe> _sortRecipes(List<CookingRecipe> recipes, String sortBy) {
    switch (sortBy) {
      case 'Rating Tertinggi':
        recipes.sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0));
        break;
      case 'Difficulty Terendah':
        recipes.sort((a, b) => a.difficulty.compareTo(b.difficulty));
        break;
      default: // Terbaru
        recipes.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
        break;
    }
    return recipes;
  }

  // Method untuk search recipe berdasarkan kategori
  Stream<List<CookingRecipe>> getRecipesByCategory(String category) {
    return _recipeService.getRecipesByCategory(category);
  }

  // Method untuk search recipe berdasarkan user
  Stream<List<CookingRecipe>> getUserRecipes(String userId) {
    return _recipeService.getUserRecipes(userId);
  }

  // Method untuk mendapatkan latest recipes
  Stream<List<CookingRecipe>> getLatestRecipes({int limit = 10}) {
    return _recipeService.getLatestRecipes(limit: limit);
  }

  // Method untuk search recipes menggunakan built-in search dari RecipeService
  Future<List<CookingRecipe>> searchRecipes(String query) async {
    return await _recipeService.searchRecipes(query);
  }
}
