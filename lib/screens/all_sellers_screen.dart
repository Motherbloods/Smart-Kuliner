// screens/all_sellers_screen.dart
import 'package:flutter/material.dart';
import 'package:smart/models/seller.dart'; // Sesuaikan dengan model seller Anda
import 'package:smart/services/seller_service.dart';
import 'package:smart/widgets/seller_card.dart'; // Sesuaikan dengan service seller Anda

class AllSellersScreen extends StatefulWidget {
  final List<SellerModel> sellers;

  const AllSellersScreen({Key? key, required this.sellers}) : super(key: key);

  @override
  State<AllSellersScreen> createState() => _AllSellersScreenState();
}

class _AllSellersScreenState extends State<AllSellersScreen> {
  final SellerService _sellerService =
      SellerService(); // Instance service Firebase

  List<SellerModel> _allSellers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllSellers();
  }

  void _loadAllSellers() {
    setState(() {
      _isLoading = true;
    });

    // Listen ke stream Firebase untuk mendapatkan semua seller
    _sellerService.getAllSellers().listen(
      (firebaseSellers) {
        setState(() {
          // Gabungkan data yang diterima dari parameter dengan data Firebase
          _allSellers = [
            ...widget.sellers, // Data seller dari parameter
            ...firebaseSellers, // Data seller dari Firebase
          ];
          _isLoading = false;
        });
      },
      onError: (error) {
        setState(() {
          // Jika error Firebase, gunakan data dari parameter saja
          _allSellers = widget.sellers;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading online sellers: $error'),
            backgroundColor: Colors.orange,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF4DA8DA),
        title: const Text(
          'Semua Toko',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _allSellers.isEmpty
          ? _buildEmptyState()
          : Column(
              children: [
                // Header info (optional)
                if (_allSellers.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Text(
                      '${_allSellers.length} toko tersedia',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Seller List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _allSellers.length,
                    itemBuilder: (context, index) {
                      final seller = _allSellers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SellerCard(seller: seller),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4DA8DA)),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat toko...',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada toko ditemukan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Belum ada toko yang terdaftar saat ini',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
