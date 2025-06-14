// seller_header_widget.dart
import 'package:flutter/material.dart';
import 'package:smart/models/seller.dart';

class SellerHeaderWidget extends StatelessWidget {
  final SellerModel? seller;

  const SellerHeaderWidget({Key? key, required this.seller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (seller == null) {
      return Container(
        height: 280,
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + kToolbarHeight,
          left: 20,
          right: 20,
          bottom: 20,
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + kToolbarHeight,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade600, Colors.blue.shade800],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundImage: seller!.profileImage.isNotEmpty
                    ? NetworkImage(seller!.profileImage)
                    : null,
                child: seller!.profileImage.isEmpty
                    ? Icon(Icons.store, size: 40, color: Colors.grey[400])
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            seller!.nameToko,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (seller!.isVerified)
                          const Icon(
                            Icons.verified,
                            color: Colors.amber,
                            size: 24,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            seller!.location,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        seller!.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatCard(
                'Rating',
                seller!.rating.toStringAsFixed(1),
                Icons.star,
                Colors.amber,
              ),
              _buildStatCard(
                'Produk',
                seller!.totalProducts.toString(),
                Icons.inventory,
                Colors.green,
              ),
              _buildStatCard(
                'Bergabung',
                '${DateTime.now().difference(seller!.joinedDate).inDays} hari',
                Icons.calendar_today,
                Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}
