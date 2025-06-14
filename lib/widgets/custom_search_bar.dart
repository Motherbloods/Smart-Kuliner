import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String searchQuery;
  final Function(String) onChanged;
  final VoidCallback onClear;
  final VoidCallback? onSearch;

  const CustomSearchBar({
    Key? key,
    required this.searchController,
    required this.searchFocusNode,
    required this.searchQuery,
    required this.onChanged,
    required this.onClear,
    this.onSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: searchController,
              focusNode: searchFocusNode,
              onChanged: onChanged,
              onSubmitted: (value) {
                if (onSearch != null && value.trim().isNotEmpty) {
                  onSearch!();
                }
              },
              decoration: InputDecoration(
                hintText: 'Cari produk kuliner...',
                hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Clear icon (x), muncul jika searchQuery tidak kosong
          if (searchQuery.isNotEmpty)
            GestureDetector(
              onTap: onClear,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.clear, color: Colors.grey[600], size: 20),
              ),
            ),

          // Search icon di luar TextField
          GestureDetector(
            onTap: () {
              if (onSearch != null && searchQuery.trim().isNotEmpty) {
                print('Performing search for: $searchQuery');
                onSearch!();
              }
            },
            child: Icon(Icons.search, color: const Color(0xFF4DA8DA), size: 24),
          ),
        ],
      ),
    );
  }
}
