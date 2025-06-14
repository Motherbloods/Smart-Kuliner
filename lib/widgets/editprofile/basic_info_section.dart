import 'package:flutter/material.dart';
import 'package:smart/models/user.dart';
import 'text_field_custom.dart';

class BasicInfoSection extends StatelessWidget {
  final UserModel userData;
  final TextEditingController nameController;
  final TextEditingController namaTokoController;

  const BasicInfoSection({
    super.key,
    required this.userData,
    required this.nameController,
    required this.namaTokoController,
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
          const Text(
            'Informasi Dasar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 20),

          // Name Field
          CustomTextField(
            controller: nameController,
            label: 'Nama Lengkap',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Nama tidak boleh kosong';
              }
              if (value.trim().length < 2) {
                return 'Nama minimal 2 karakter';
              }
              return null;
            },
          ),

          if (userData.seller) ...[
            const SizedBox(height: 20),
            CustomTextField(
              controller: namaTokoController,
              label: 'Nama Toko',
              icon: Icons.store_outlined,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Nama toko tidak boleh kosong';
                }
                if (value.trim().length < 3) {
                  return 'Nama toko minimal 3 karakter';
                }
                return null;
              },
            ),
          ],

          const SizedBox(height: 20),

          _buildReadOnlyField(
            label: 'Email',
            value: userData.email,
            icon: Icons.email_outlined,
          ),
        ],
      ),
    );
  }
}

Widget _buildReadOnlyField({
  required String label,
  required String value,
  required IconData icon,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF4A5568),
        ),
      ),
      const SizedBox(height: 8),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[50],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[500], size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ),
            Icon(Icons.lock_outline, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    ],
  );
}
