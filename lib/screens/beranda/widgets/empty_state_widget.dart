import 'package:flutter/material.dart';

class EmptyStateWidget extends StatelessWidget {
  final bool isSearchActive;
  final String searchQuery;

  const EmptyStateWidget({
    Key? key,
    required this.isSearchActive,
    required this.searchQuery,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📦', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              isSearchActive && searchQuery.isNotEmpty
                  ? 'Produk tidak ditemukan'
                  : 'Belum ada produk',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isSearchActive && searchQuery.isNotEmpty
                  ? 'Coba kata kunci lain atau ubah kategori'
                  : 'Tambahkan produk pertama Anda',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
