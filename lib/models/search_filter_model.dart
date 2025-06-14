import 'package:smart/widgets/search_result_type.dart';

class SearchFilterModel {
  SearchResultType resultType;
  String selectedCategory;
  double minPrice;
  double maxPrice;
  double minRating;
  String sortBy;
  bool onlyVerifiedSellers; // New filter for sellers

  SearchFilterModel({
    this.resultType = SearchResultType.all,
    this.selectedCategory = 'Semua',
    this.minPrice = 0,
    this.maxPrice = 100000,
    this.minRating = 0,
    this.sortBy = 'Terbaru',
    this.onlyVerifiedSellers = false,
  });

  SearchFilterModel copyWith({
    SearchResultType? resultType,
    String? selectedCategory,
    double? minPrice,
    double? maxPrice,
    double? minRating,
    String? sortBy,
    bool? onlyVerifiedSellers,
  }) {
    return SearchFilterModel(
      resultType: resultType ?? this.resultType,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
      sortBy: sortBy ?? this.sortBy,
      onlyVerifiedSellers: onlyVerifiedSellers ?? this.onlyVerifiedSellers,
    );
  }

  void reset() {
    selectedCategory = 'Semua';
    minPrice = 0;
    maxPrice = 100000;
    minRating = 0;
    sortBy = 'Terbaru';
    resultType = SearchResultType.all;
  }

  Map<String, dynamic> toMap() {
    return {
      'resultType': resultType.toString(),
      'selectedCategory': selectedCategory,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'minRating': minRating,
      'sortBy': sortBy,
      'onlyVerifiedSellers': onlyVerifiedSellers,
    };
  }

  factory SearchFilterModel.fromMap(Map<String, dynamic> map) {
    return SearchFilterModel(
      resultType: _parseResultType(map['resultType']),
      selectedCategory: map['selectedCategory'] ?? 'Semua',
      minPrice: (map['minPrice'] ?? 0).toDouble(),
      maxPrice: (map['maxPrice'] ?? 100000).toDouble(),
      minRating: (map['minRating'] ?? 0).toDouble(),
      sortBy: map['sortBy'] ?? 'Terbaru',
      onlyVerifiedSellers: map['onlyVerifiedSellers'] ?? false,
    );
  }

  static SearchResultType _parseResultType(String? type) {
    switch (type) {
      case 'SearchResultType.products':
        return SearchResultType.products;
      case 'SearchResultType.edukasi':
        return SearchResultType.edukasi;
      case 'SearchResultType.sellers':
        return SearchResultType.sellers;
      default:
        return SearchResultType.all;
    }
  }

  @override
  String toString() {
    return 'SearchFilterModel(resultType: $resultType, selectedCategory: $selectedCategory, minPrice: $minPrice, maxPrice: $maxPrice, minRating: $minRating, sortBy: $sortBy, onlyVerifiedSellers: $onlyVerifiedSellers)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SearchFilterModel &&
        other.resultType == resultType &&
        other.selectedCategory == selectedCategory &&
        other.minPrice == minPrice &&
        other.maxPrice == maxPrice &&
        other.minRating == minRating &&
        other.sortBy == sortBy &&
        other.onlyVerifiedSellers == onlyVerifiedSellers;
  }

  @override
  int get hashCode {
    return resultType.hashCode ^
        selectedCategory.hashCode ^
        minPrice.hashCode ^
        maxPrice.hashCode ^
        minRating.hashCode ^
        sortBy.hashCode ^
        onlyVerifiedSellers.hashCode;
  }
}
