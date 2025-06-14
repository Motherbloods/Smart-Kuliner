// services/product_service.dart - Updated version
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import 'cloudinary_service.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Get all active products (untuk halaman beranda)
  Stream<List<ProductModel>> getAllActiveProducts() {
    return _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ProductModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  Stream<List<ProductModel>> getLatestProducts({int limit = 10}) {
    return _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ProductModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get all products for a specific seller
  Stream<List<ProductModel>> getSellerProducts(String sellerId) {
    return _firestore
        .collection('products')
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ProductModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get products by category
  Stream<List<ProductModel>> getProductsByCategory(String category) {
    return _firestore
        .collection('products')
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ProductModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get popular products (berdasarkan jumlah terjual)
  Stream<List<ProductModel>> getPopularProducts({int limit = 10}) {
    return _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .orderBy('sold', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ProductModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get single product by ID
  Future<ProductModel?> getProduct(String productId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('products')
          .doc(productId)
          .get();

      if (doc.exists) {
        return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  // Add new product
  Future<String?> addProduct(ProductModel product) async {
    try {
      DocumentReference docRef = await _firestore
          .collection('products')
          .add(product.toMap());

      print('✅ Product added successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding product: $e');
      throw 'Gagal menambahkan produk: $e';
    }
  }

  // Update product
  Future<void> updateProduct(String productId, ProductModel product) async {
    try {
      await _firestore
          .collection('products')
          .doc(productId)
          .update(product.toMap());

      print('✅ Product updated successfully');
    } catch (e) {
      print('❌ Error updating product: $e');
      throw 'Gagal memperbarui produk: $e';
    }
  }

  // Delete product
  Future<void> deleteProduct(String productId) async {
    try {
      // Get product data first to delete images
      DocumentSnapshot doc = await _firestore
          .collection('products')
          .doc(productId)
          .get();

      if (doc.exists) {
        ProductModel product = ProductModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        // Delete images from Cloudinary
        for (String imageUrl in product.imageUrls) {
          await _cloudinaryService.deleteImage(imageUrl);
        }
      }

      // Delete product document
      await _firestore.collection('products').doc(productId).delete();

      print('✅ Product deleted successfully');
    } catch (e) {
      print('❌ Error deleting product: $e');
      throw 'Gagal menghapus produk: $e';
    }
  }

  // Upload images to Cloudinary
  Future<List<String>> uploadProductImages(
    List<XFile> imageFiles,
    String sellerId,
  ) async {
    try {
      // Create folder path for better organization
      String folderPath = 'products/$sellerId';

      // Upload to Cloudinary
      List<String> imageUrls = await _cloudinaryService.uploadMultipleImages(
        imageFiles,
        folderPath,
      );

      print('✅ ${imageUrls.length} images uploaded successfully to Cloudinary');
      return imageUrls;
    } catch (e) {
      print('❌ Error uploading images: $e');
      throw 'Gagal mengupload gambar: $e';
    }
  }

  // Search products
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();

      List<ProductModel> products = snapshot.docs.map((doc) {
        return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Filter by name, description, or restaurant
      return products
          .where(
            (product) =>
                product.name.toLowerCase().contains(query.toLowerCase()) ||
                product.description.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    } catch (e) {
      print('❌ Error searching products: $e');
      return [];
    }
  }

  // Get optimized image URLs for different use cases
  List<String> getOptimizedImageUrls(
    List<String> originalUrls, {
    int? width,
    int? height,
    String quality = 'auto:good',
  }) {
    return originalUrls.map((url) {
      return _cloudinaryService.getOptimizedImageUrl(
        url,
        width: width,
        height: height,
        quality: quality,
      );
    }).toList();
  }

  // Get thumbnail URLs (untuk list produk)
  List<String> getThumbnailUrls(List<String> originalUrls) {
    return getOptimizedImageUrls(
      originalUrls,
      width: 300,
      height: 300,
      quality: 'auto:low',
    );
  }

  // Get medium size URLs (untuk detail produk)
  List<String> getMediumSizeUrls(List<String> originalUrls) {
    return getOptimizedImageUrls(
      originalUrls,
      width: 800,
      height: 600,
      quality: 'auto:good',
    );
  }

  // Get product categories
  List<String> getProductCategories() {
    return [
      'Makanan Utama',
      'Cemilan',
      'Minuman',
      'Makanan Sehat',
      'Dessert',
      'Lainnya',
    ];
  }

  // Toggle product active status
  Future<void> toggleProductStatus(String productId, bool isActive) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'isActive': isActive,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Product status updated successfully');
    } catch (e) {
      print('❌ Error updating product status: $e');
      throw 'Gagal memperbarui status produk: $e';
    }
  }

  // Update product rating (dipanggil setelah ada review)
  Future<void> updateProductRating(String productId, double newRating) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'rating': newRating,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      print('✅ Product rating updated successfully');
    } catch (e) {
      print('❌ Error updating product rating: $e');
      throw 'Gagal memperbarui rating produk: $e';
    }
  }

  // Update product sold count (dipanggil setelah ada transaksi)
  Future<void> updateProductSoldCount(
    String productId,
    int additionalSold,
  ) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('products')
          .doc(productId)
          .get();

      if (doc.exists) {
        ProductModel product = ProductModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        await _firestore.collection('products').doc(productId).update({
          'sold': product.sold + additionalSold,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        print('✅ Product sold count updated successfully');
      }
    } catch (e) {
      print('❌ Error updating product sold count: $e');
      throw 'Gagal memperbarui jumlah terjual: $e';
    }
  }

  // Get products by restaurant/seller
  Stream<List<ProductModel>> getProductsByRestaurant(String restaurant) {
    return _firestore
        .collection('products')
        .where('restaurant', isEqualTo: restaurant)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ProductModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get products with price range filter
  Stream<List<ProductModel>> getProductsByPriceRange(
    double minPrice,
    double maxPrice,
  ) {
    return _firestore
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('price', isGreaterThanOrEqualTo: minPrice)
        .where('price', isLessThanOrEqualTo: maxPrice)
        .orderBy('price')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ProductModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }
}
