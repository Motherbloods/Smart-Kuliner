import 'package:flutter/material.dart';
import 'package:smart/models/user.dart';

class AddressSection extends StatelessWidget {
  final TextEditingController controller;
  final UserModel? userModel;

  const AddressSection({super.key, required this.controller, this.userModel});

  @override
  Widget build(BuildContext context) {
    if (controller.text.isEmpty && userModel?.address != null) {
      controller.text = userModel!.address!;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.location_on, color: Color(0xFF4DA8DA), size: 20),
              SizedBox(width: 8),
              Text(
                'Alamat Pengiriman',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Masukkan alamat lengkap Anda...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFFE0E0E0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: Color(0xFF4DA8DA)),
              ),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
