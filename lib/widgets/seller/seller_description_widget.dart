// seller_description_widget.dart
import 'package:flutter/material.dart';
import 'package:smart/models/seller.dart';

class SellerDescriptionWidget extends StatelessWidget {
  final SellerModel? seller; // ganti SellerModel sesuai tipe seller kamu

  const SellerDescriptionWidget({Key? key, required this.seller})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (seller?.description.isEmpty ?? true) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tentang Toko',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            seller!.description,
            style: TextStyle(color: Colors.grey.shade700, height: 1.5),
          ),
        ],
      ),
    );
  }
}
