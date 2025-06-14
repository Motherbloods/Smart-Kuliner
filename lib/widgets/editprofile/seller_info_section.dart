import 'package:flutter/material.dart';
import 'package:smart/widgets/editprofile/text_field_custom.dart';

class SellerInfoSection extends StatelessWidget {
  final TextEditingController descriptionController;
  final TextEditingController locationController;
  final Widget categoryDropdown;

  const SellerInfoSection({
    super.key,
    required this.descriptionController,
    required this.locationController,
    required this.categoryDropdown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store, color: Colors.green[600], size: 24),
              const SizedBox(width: 8),
              const Text(
                'Informasi Toko',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          CustomTextField(
            controller: descriptionController,
            label: 'Deskripsi Toko',
            icon: Icons.description_outlined,
            maxLines: 3,
            validator: (value) {
              if (value != null &&
                  value.trim().isNotEmpty &&
                  value.trim().length < 10) {
                return 'Deskripsi minimal 10 karakter';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          CustomTextField(
            controller: locationController,
            label: 'Lokasi Toko',
            icon: Icons.location_on_outlined,
            validator: (value) {
              if (value != null &&
                  value.trim().isNotEmpty &&
                  value.trim().length < 5) {
                return 'Lokasi minimal 5 karakter';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),

          categoryDropdown,

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
