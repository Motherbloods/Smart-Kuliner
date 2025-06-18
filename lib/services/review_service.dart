// services/review_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/review.dart';
import 'cloudinary_service.dart';
import 'product_service.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();
  final ProductService _productService = ProductService();

  // Add new review
  Future<String?> addReview(
    ReviewModel review, {
    List<XFile>? imageFiles,
  }) async {
    try {
      // Upload images if provided
      List<String> imageUrls = [];
      if (imageFiles != null && imageFiles.isNotEmpty) {
        String folderPath = 'reviews/${review.productId}';
        imageUrls = await _cloudinaryService.uploadMultipleImages(
          imageFiles,
          folderPath,
        );
      }

      // Create review with uploaded image URLs
      final reviewWithImages = review.copyWith(imageUrls: imageUrls);

      // Add review to Firestore
      DocumentReference docRef = await _firestore
          .collection('reviews')
          .add(reviewWithImages.toMap());

      // Update product rating
      await _updateProductRating(review.productId);

      print('✅ Review added successfully with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error adding review: $e');
      throw 'Gagal menambahkan ulasan: $e';
    }
  }

  // Get reviews for a product
  Stream<List<ReviewModel>> getProductReviews(String productId) {
    return _firestore
        .collection('reviews')
        .where('productId', isEqualTo: productId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ReviewModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Get reviews by user
  Stream<List<ReviewModel>> getUserReviews(String userId) {
    return _firestore
        .collection('reviews')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ReviewModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Update review
  Future<void> updateReview(
    String reviewId,
    ReviewModel review, {
    List<XFile>? newImageFiles,
  }) async {
    try {
      List<String> imageUrls = review.imageUrls;

      // Upload new images if provided
      if (newImageFiles != null && newImageFiles.isNotEmpty) {
        // Delete old images
        for (String imageUrl in review.imageUrls) {
          await _cloudinaryService.deleteImage(imageUrl);
        }

        // Upload new images
        String folderPath = 'reviews/${review.productId}';
        imageUrls = await _cloudinaryService.uploadMultipleImages(
          newImageFiles,
          folderPath,
        );
      }

      // Update review with new data and images
      final updatedReview = review.copyWith(
        imageUrls: imageUrls,
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('reviews')
          .doc(reviewId)
          .update(updatedReview.toMap());

      // Update product rating
      await _updateProductRating(review.productId);

      print('✅ Review updated successfully');
    } catch (e) {
      print('❌ Error updating review: $e');
      throw 'Gagal memperbarui ulasan: $e';
    }
  }

  // Delete review
  Future<void> deleteReview(String reviewId, String productId) async {
    try {
      // Get review data first to delete images
      DocumentSnapshot doc = await _firestore
          .collection('reviews')
          .doc(reviewId)
          .get();

      if (doc.exists) {
        ReviewModel review = ReviewModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );

        // Delete images from Cloudinary
        for (String imageUrl in review.imageUrls) {
          await _cloudinaryService.deleteImage(imageUrl);
        }
      }

      // Delete review document
      await _firestore.collection('reviews').doc(reviewId).delete();

      // Update product rating
      await _updateProductRating(productId);

      print('✅ Review deleted successfully');
    } catch (e) {
      print('❌ Error deleting review: $e');
      throw 'Gagal menghapus ulasan: $e';
    }
  }

  // Get review statistics for a product
  Future<Map<String, dynamic>> getReviewStatistics(String productId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('reviews')
          .where('productId', isEqualTo: productId)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'totalReviews': 0,
          'averageRating': 0.0,
          'ratingDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
        };
      }

      List<ReviewModel> reviews = snapshot.docs.map((doc) {
        return ReviewModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Calculate statistics
      double totalRating = 0;
      Map<int, int> ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

      for (ReviewModel review in reviews) {
        totalRating += review.rating;
        ratingDistribution[review.rating.round()] =
            (ratingDistribution[review.rating.round()] ?? 0) + 1;
      }

      double averageRating = totalRating / reviews.length;

      return {
        'totalReviews': reviews.length,
        'averageRating': averageRating,
        'ratingDistribution': ratingDistribution,
      };
    } catch (e) {
      print('❌ Error getting review statistics: $e');
      return {
        'totalReviews': 0,
        'averageRating': 0.0,
        'ratingDistribution': {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      };
    }
  }

  // Check if user can review product (has completed order)
  Future<bool> canUserReviewProduct(String userId, String productId) async {
    try {
      // Check if user has completed order for this product
      QuerySnapshot orderSnapshot = await _firestore
          .collection('orders')
          .where('buyerId', isEqualTo: userId)
          .where('status', isEqualTo: 'completed')
          .get();

      for (QueryDocumentSnapshot orderDoc in orderSnapshot.docs) {
        Map<String, dynamic> orderData =
            orderDoc.data() as Map<String, dynamic>;
        List<dynamic> items = orderData['items'] ?? [];

        for (dynamic item in items) {
          if (item['productId'] == productId) {
            // Check if user already reviewed this product
            QuerySnapshot reviewSnapshot = await _firestore
                .collection('reviews')
                .where('userId', isEqualTo: userId)
                .where('productId', isEqualTo: productId)
                .get();

            return reviewSnapshot.docs.isEmpty;
          }
        }
      }

      return false;
    } catch (e) {
      print('❌ Error checking review permission: $e');
      return false;
    }
  }

  // Private method to update product rating
  Future<void> _updateProductRating(String productId) async {
    try {
      Map<String, dynamic> stats = await getReviewStatistics(productId);
      double averageRating = stats['averageRating'];

      await _productService.updateProductRating(productId, averageRating);
    } catch (e) {
      print('❌ Error updating product rating: $e');
    }
  }

  // Get latest reviews (for home page or general display)
  Stream<List<ReviewModel>> getLatestReviews({int limit = 10}) {
    return _firestore
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return ReviewModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // Upload review images
  Future<List<String>> uploadReviewImages(
    List<XFile> imageFiles,
    String productId,
  ) async {
    try {
      String folderPath = 'reviews/$productId';
      List<String> imageUrls = await _cloudinaryService.uploadMultipleImages(
        imageFiles,
        folderPath,
      );

      print('✅ ${imageUrls.length} review images uploaded successfully');
      return imageUrls;
    } catch (e) {
      print('❌ Error uploading review images: $e');
      throw 'Gagal mengupload gambar ulasan: $e';
    }
  }
}
