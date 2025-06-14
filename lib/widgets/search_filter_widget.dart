import 'package:flutter/material.dart';
import 'package:smart/models/search_filter_model.dart';
import 'package:smart/services/search_service.dart';
import 'package:smart/widgets/search_result_type.dart';

class SearchFilterWidget extends StatelessWidget {
  final SearchFilterModel filter;
  final double maxPriceAvailable;
  final Function(SearchFilterModel) onFilterChanged;
  final VoidCallback onResetFilters;

  const SearchFilterWidget({
    Key? key,
    required this.filter,
    required this.maxPriceAvailable,
    required this.onFilterChanged,
    required this.onResetFilters,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: onResetFilters,
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      color: Color(0xFF4DA8DA),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Result Type Filter
          _buildResultTypeFilter(),

          const Divider(height: 1),

          // Category Filter
          _buildCategoryFilter(),

          // Price Filter (only for products)
          if (filter.resultType == SearchResultType.products ||
              filter.resultType == SearchResultType.all) ...[
            const Divider(height: 1),
            _buildPriceFilter(),
          ],

          // Rating Filter
          const Divider(height: 1),
          _buildRatingFilter(),

          // Verified Sellers Filter (only for sellers)
          if (filter.resultType == SearchResultType.sellers ||
              filter.resultType == SearchResultType.all) ...[
            const Divider(height: 1),
            _buildVerifiedSellersFilter(),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildResultTypeFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jenis Hasil',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: SearchResultType.values.map((type) {
              final isSelected = filter.resultType == type;
              final label = _getResultTypeLabel(type);

              return FilterChip(
                label: Text(label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    onFilterChanged(filter.copyWith(resultType: type));
                  }
                },
                selectedColor: const Color(0xFF4DA8DA).withOpacity(0.2),
                checkmarkColor: const Color(0xFF4DA8DA),
                labelStyle: TextStyle(
                  color: isSelected
                      ? const Color(0xFF4DA8DA)
                      : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: SearchService.categories.map((category) {
              final isSelected = filter.selectedCategory == category;

              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  onFilterChanged(
                    filter.copyWith(
                      selectedCategory: selected ? category : 'Semua',
                    ),
                  );
                },
                selectedColor: const Color(0xFF4DA8DA).withOpacity(0.2),
                checkmarkColor: const Color(0xFF4DA8DA),
                labelStyle: TextStyle(
                  color: isSelected
                      ? const Color(0xFF4DA8DA)
                      : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rentang Harga',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Rp ${filter.minPrice.toInt()}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              Text(
                'Rp ${filter.maxPrice.toInt()}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          RangeSlider(
            values: RangeValues(filter.minPrice, filter.maxPrice),
            min: 0,
            max: maxPriceAvailable,
            divisions: 20,
            activeColor: const Color(0xFF4DA8DA),
            inactiveColor: const Color(0xFF4DA8DA).withOpacity(0.3),
            onChanged: (values) {
              onFilterChanged(
                filter.copyWith(minPrice: values.start, maxPrice: values.end),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRatingFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rating Minimum',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('0'),
              Expanded(
                child: Slider(
                  value: filter.minRating,
                  min: 0,
                  max: 5,
                  divisions: 10,
                  activeColor: const Color(0xFF4DA8DA),
                  inactiveColor: const Color(0xFF4DA8DA).withOpacity(0.3),
                  onChanged: (value) {
                    onFilterChanged(filter.copyWith(minRating: value));
                  },
                ),
              ),
              const Text('5'),
            ],
          ),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  filter.minRating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4DA8DA),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedSellersFilter() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Hanya Toko Terverifikasi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Switch(
            value: filter.onlyVerifiedSellers,
            onChanged: (value) {
              onFilterChanged(filter.copyWith(onlyVerifiedSellers: value));
            },
            activeColor: const Color(0xFF4DA8DA),
          ),
        ],
      ),
    );
  }

  String _getResultTypeLabel(SearchResultType type) {
    switch (type) {
      case SearchResultType.all:
        return 'Semua';
      case SearchResultType.products:
        return 'Produk';
      case SearchResultType.edukasi:
        return 'Edukasi';
      case SearchResultType.sellers:
        return 'Toko';
    }
  }
}
