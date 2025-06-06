// widgets/product_card.dart - Updated version
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../services/product_service.dart';

class ProductCard extends StatelessWidget {
  final dynamic
  product; // Bisa ProductModel atau Map (untuk backward compatibility)

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ProductService _productService = ProductService();

    // Handle both ProductModel and Map
    final String name = product is ProductModel
        ? product.name
        : product['name'] ?? '';
    final String description = product is ProductModel
        ? product.description
        : product['description'] ?? '';
    final double price = product is ProductModel
        ? product.price
        : (product['price'] as num?)?.toDouble() ?? 0.0;
    final double rating = product is ProductModel
        ? product.rating
        : (product['rating'] as num?)?.toDouble() ?? 0.0;
    final int sold = product is ProductModel
        ? product.sold
        : product['sold'] ?? 0;

    final String nameToko = product is ProductModel
        ? product.nameToko
        : product['nameToko'] ?? '';

    // Handle image URLs
    List<String> imageUrls = [];
    if (product is ProductModel) {
      imageUrls = product.imageUrls;
    } else {
      // For dummy data compatibility
      if (product['image'] != null) {
        imageUrls = [product['image']];
      } else if (product['imageUrls'] != null) {
        imageUrls = List<String>.from(product['imageUrls']);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: _buildProductImage(imageUrls, _productService),
            ),
          ),

          // Product Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      description,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (nameToko.isNotEmpty)
                    Text(
                      nameToko,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 12),
                          const SizedBox(width: 2),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              '$sold terjual',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatPrice(price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method untuk build product image
  Widget _buildProductImage(
    List<String> imageUrls,
    ProductService productService,
  ) {
    if (imageUrls.isEmpty) {
      // Default placeholder jika tidak ada gambar
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
        ),
      );
    }

    String imageUrl = imageUrls.first;

    // Jika URL adalah emoji atau text (untuk backward compatibility dengan dummy data)
    if (!imageUrl.startsWith('http')) {
      return Container(
        color: Colors.grey[100],
        child: Center(
          child: Text(imageUrl, style: const TextStyle(fontSize: 40)),
        ),
      );
    }

    // Gunakan optimized thumbnail untuk performa yang lebih baik
    String optimizedUrl = productService
        .getOptimizedImageUrls(
          [imageUrl],
          width: 300,
          height: 300,
          quality: 'auto:low',
        )
        .first;

    return CachedNetworkImage(
      imageUrl: optimizedUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      placeholder: (context, url) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B35)),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[200],
        child: const Center(
          child: Icon(Icons.broken_image, size: 40, color: Colors.grey),
        ),
      ),
    );
  }

  // Helper method untuk format price
  String _formatPrice(double price) {
    if (product is ProductModel) {
      // Gunakan method dari ProductModel jika tersedia
      return (product as ProductModel).formattedPrice;
    }

    // Format manual jika bukan ProductModel
    return 'Rp ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }
}
