import 'package:flutter/material.dart';
import 'package:smart/models/seller.dart';
import 'package:smart/screens/seller_detail_screen.dart';

class SellerCard extends StatelessWidget {
  final SellerModel seller;

  const SellerCard({Key? key, required this.seller}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          // Navigate to seller detail page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SellerDetailScreen(sellerId: seller.id),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Seller Profile Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(25),
                    child: seller.profileImage.isNotEmpty
                        ? Image.network(
                            seller.profileImage,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildDefaultAvatar();
                            },
                          )
                        : _buildDefaultAvatar(),
                  ),
                  const SizedBox(width: 12),

                  // Seller Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                seller.nameToko,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (seller.isVerified)
                              const Icon(
                                Icons.verified,
                                color: Color(0xFF4DA8DA),
                                size: 18,
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          seller.location,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              seller.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${seller.totalProducts} produk',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (seller.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  seller.description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Category and Tags
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4DA8DA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      seller.category,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF4DA8DA),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Bergabung ${_formatJoinDate(seller.joinedDate)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF4DA8DA).withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: const Icon(Icons.store, color: Color(0xFF4DA8DA), size: 24),
    );
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} tahun lalu';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} bulan lalu';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} hari lalu';
    } else {
      return 'Hari ini';
    }
  }
}
