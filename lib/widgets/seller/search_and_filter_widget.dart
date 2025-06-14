// search_and_filter_widget.dart
import 'package:flutter/material.dart';

class SearchAndFilterWidget extends StatelessWidget {
  final TextEditingController searchController;
  final List<String> categories;
  final String? selectedCategory;
  final void Function(String?) onCategorySelected;
  final VoidCallback onClear;
  final VoidCallback onSearchChanged;

  const SearchAndFilterWidget({
    Key? key,
    required this.searchController,
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
    required this.onClear,
    required this.onSearchChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Cari produk...',
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClear,
                    )
                  : null,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (_) => onSearchChanged(),
          ),
          const SizedBox(height: 16),

          // Category filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      onCategorySelected(category);
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue.shade700,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
