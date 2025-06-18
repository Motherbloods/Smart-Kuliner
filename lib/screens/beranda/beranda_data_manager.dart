// screens/beranda/beranda_data_manager.dart
import 'dart:async';
import 'package:smart/models/konten.dart';
import 'package:smart/models/product.dart';
import 'package:smart/models/edukasi.dart';
import 'package:smart/models/user.dart';
import 'package:smart/services/konten_service.dart';
import 'package:smart/services/product_service.dart';
import 'package:smart/services/edukasi_service.dart';

class BerandaState {
  final bool isLoading;
  final String? error;
  final List<ProductModel> latestProducts;
  final List<EdukasiModel> latestEducation;
  final List<ProductModel> sellerProducts;
  final List<KontenModel> latestKonten;
  final String selectedCategory;

  BerandaState({
    this.isLoading = false,
    this.error,
    this.latestProducts = const [],
    this.latestEducation = const [],
    this.sellerProducts = const [],
    this.latestKonten = const [],
    this.selectedCategory = 'Semua',
  });

  BerandaState copyWith({
    bool? isLoading,
    String? error,
    List<ProductModel>? latestProducts,
    List<EdukasiModel>? latestEducation,
    List<KontenModel>? latestKonten,
    List<ProductModel>? sellerProducts,
    String? selectedCategory,
  }) {
    return BerandaState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      latestProducts: latestProducts ?? this.latestProducts,
      latestEducation: latestEducation ?? this.latestEducation,
      latestKonten: latestKonten ?? this.latestKonten,
      sellerProducts: sellerProducts ?? this.sellerProducts,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

class BerandaDataManager {
  final ProductService _productService = ProductService();
  final EdukasiService _edukasiService = EdukasiService();
  final KontenService _kontenService = KontenService();

  final StreamController<BerandaState> _stateController =
      StreamController<BerandaState>.broadcast();
  BerandaState _currentState = BerandaState();

  Stream<BerandaState> get stateStream => _stateController.stream;
  BerandaState get currentState => _currentState;

  final List<String> categories = [
    'Semua',
    'Makanan Utama',
    'Cemilan',
    'Minuman',
    'Makanan Sehat',
    'Dessert',
    "Lainnya",
  ];

  void _updateState(BerandaState newState) {
    _currentState = newState;
    _stateController.add(newState);
  }

  void loadData(UserModel? currentUser) {
    if (currentUser?.seller == true) {
      _loadSellerData(currentUser!);
    } else {
      _loadUserData();
    }
  }

  void refreshData(UserModel? currentUser) {
    loadData(currentUser);
  }

  void _loadUserData() {
    _updateState(_currentState.copyWith(isLoading: true, error: null));

    // Load latest products
    _productService
        .getLatestProducts(limit: 4)
        .listen(
          (products) {
            _updateState(_currentState.copyWith(latestProducts: products));
          },
          onError: (error) {
            print('❌ Error loading latest products: $error');
            _updateState(
              _currentState.copyWith(error: 'Gagal memuat produk: $error'),
            );
          },
        );

    // Load latest education
    _loadLatestEducation();

    // Load latest konten
    _loadLatestKonten();

    _updateState(_currentState.copyWith(isLoading: false));
  }

  void _loadSellerData(UserModel currentUser) {
    _updateState(_currentState.copyWith(isLoading: true, error: null));

    _productService
        .getSellerProducts(currentUser.uid)
        .listen(
          (products) {
            _updateState(
              _currentState.copyWith(
                sellerProducts: products,
                isLoading: false,
                error: null,
              ),
            );
            print('✅ Loaded ${products.length} seller products');
          },
          onError: (error) {
            _updateState(
              _currentState.copyWith(
                isLoading: false,
                error: 'Gagal memuat produk: $error',
              ),
            );
            print('❌ Error loading seller products: $error');
          },
        );
  }

  Future<void> _loadLatestEducation() async {
    try {
      final educationData = await _edukasiService.getLatestEdukasi(limit: 3);
      _updateState(_currentState.copyWith(latestEducation: educationData));
    } catch (e) {
      print('❌ Error loading latest education: $e');
    }
  }

  Future<void> _loadLatestKonten() async {
    try {
      final snapshot = await _kontenService.getLatestKonten(limit: 3);
      _updateState(_currentState.copyWith(latestKonten: snapshot));
    } catch (e) {
      print('❌ Error loading latest konten: $e');
    }
  }

  void setSelectedCategory(String category) {
    _updateState(_currentState.copyWith(selectedCategory: category));
  }

  List<ProductModel> getFilteredSellerProducts({
    required String searchQuery,
    required bool isSearchActive,
  }) {
    return _currentState.sellerProducts.where((product) {
      final matchesSearch =
          !isSearchActive ||
          searchQuery.isEmpty ||
          product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(searchQuery.toLowerCase());

      final matchesCategory =
          _currentState.selectedCategory == 'Semua' ||
          product.category == _currentState.selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();
  }

  void dispose() {
    _stateController.close();
  }
}
