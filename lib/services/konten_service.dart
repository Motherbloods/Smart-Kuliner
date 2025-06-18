import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/konten.dart';
import 'cloudinary_service.dart';

class KontenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Collection reference
  CollectionReference get _kontenCollection => _firestore.collection('konten');

  // Get konten categories
  List<String> getKontenCategories() {
    return [
      'Semua',
      'Makanan Utama',
      'Cemilan',
      'Minuman',
      'Makanan Sehat',
      'Dessert',
      "Lainnya",
    ];
  }

  // ========== IMAGE METHODS ==========
  /// Upload image to Cloudinary
  Future<String> uploadImage(XFile imageFile, String sellerId) async {
    try {
      // Validate image file
      if (!_cloudinaryService.isValidImageFile(imageFile)) {
        throw Exception('Format gambar tidak didukung');
      }

      // Check file size (max 10MB)
      if (!await _cloudinaryService.isValidImageSize(imageFile)) {
        throw Exception('Ukuran gambar terlalu besar (maksimal 10MB)');
      }

      // Create folder path for images
      final String folder = 'konten/images/$sellerId';

      // Upload to Cloudinary
      final String imageUrl = await _cloudinaryService.uploadImage(
        imageFile,
        folder,
      );

      return imageUrl;
    } catch (e) {
      throw Exception('Gagal mengupload gambar: $e');
    }
  }

  /// Calculate read time based on content length (estimated)
  int calculateReadTime(String description) {
    // Estimate reading time: ~200 words per minute
    final wordCount = description.split(' ').length;
    final readTimeMinutes = (wordCount / 200).ceil();
    return readTimeMinutes.clamp(1, 30); // Min 1 minute, max 30 minutes
  }

  /// Validate image file
  bool isValidImageFile(XFile file) {
    return _cloudinaryService.isValidImageFile(file);
  }

  /// Get image file size in MB
  Future<double> getImageFileSize(XFile imageFile) async {
    try {
      return await _cloudinaryService.getImageFileSize(imageFile);
    } catch (e) {
      throw Exception('Gagal mendapatkan ukuran file gambar: $e');
    }
  }

  /// Validate image file size
  Future<bool> isValidImageSize(
    XFile imageFile, {
    double maxSizeMB = 10.0,
  }) async {
    try {
      return await _cloudinaryService.isValidImageSize(
        imageFile,
        maxSizeMB: maxSizeMB,
      );
    } catch (e) {
      return false;
    }
  }

  /// Delete image from Cloudinary
  Future<void> deleteImage(String imageUrl) async {
    try {
      await _cloudinaryService.deleteImage(imageUrl);
    } catch (e) {
      print('⚠️ Error deleting image: $e');
      // Don't throw error as it's not critical
    }
  }

  /// Get optimized image URL with transformations
  String getOptimizedImageUrl(
    String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto:good',
    String format = 'auto',
  }) {
    return _cloudinaryService.getOptimizedImageUrl(
      originalUrl,
      width: width,
      height: height,
      quality: quality,
      format: format,
    );
  }

  // ========== FIRESTORE CRUD METHODS ==========

  /// Add new konten to Firestore
  Future<void> addKonten(KontenModel konten) async {
    try {
      // Add to Firestore (auto-generate ID)
      final DocumentReference docRef = await _kontenCollection.add(
        konten.toJson(),
      );

      // Update with the generated ID
      await docRef.update({'id': docRef.id});
    } catch (e) {
      throw Exception('Gagal menambahkan konten: $e');
    }
  }

  /// Get all konten content
  Future<List<KontenModel>> getAllKonten() async {
    try {
      final QuerySnapshot snapshot = await _kontenCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => KontenModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data konten: $e');
    }
  }

  /// Get konten by seller ID
  Future<List<KontenModel>> getKontenBySeller(String sellerId) async {
    try {
      final QuerySnapshot snapshot = await _kontenCollection
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => KontenModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data konten seller: $e');
    }
  }

  Future<List<KontenModel>> getLatestKonten({int limit = 3}) async {
    try {
      final QuerySnapshot snapshot = await _kontenCollection
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(
            (doc) => KontenModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data konten terbaru: $e');
    }
  }

  /// Get konten by category
  Future<List<KontenModel>> getKontenByCategory(String category) async {
    try {
      final QuerySnapshot snapshot = await _kontenCollection
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'Published')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => KontenModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data konten kategori: $e');
    }
  }

  /// Get published konten only
  Future<List<KontenModel>> getPublishedKonten() async {
    try {
      final QuerySnapshot snapshot = await _kontenCollection
          .where('status', isEqualTo: 'Published')
          .get();
      final kontenList =
          snapshot.docs
              .map(
                (doc) =>
                    KontenModel.fromJson(doc.data() as Map<String, dynamic>),
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return kontenList;
    } catch (e) {
      throw Exception('Gagal mengambil data konten published: $e');
    }
  }

  /// Update konten
  Future<void> updateKonten(KontenModel konten) async {
    try {
      if (konten.id == null || konten.id!.isEmpty) {
        throw Exception('ID konten tidak valid');
      }

      // Update document di Firestore menggunakan ID yang benar
      await _kontenCollection.doc(konten.id).update({
        'title': konten.title,
        'description': konten.description,
        'category': konten.category,
        'imageUrl': konten.imageUrl,
        'status': konten.status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Konten updated successfully: ${konten.id}');
    } catch (e) {
      print('❌ Error updating konten: $e');
      throw Exception('Gagal mengupdate konten: $e');
    }
  }

  /// Delete konten (with media cleanup)
  Future<void> deleteKonten(String kontenId) async {
    try {
      // Get konten data first to clean up media files
      final DocumentSnapshot doc = await _kontenCollection.doc(kontenId).get();

      print('Deleting konten: ${doc.id}');

      if (doc.exists) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Delete image from Cloudinary if exists
        if (data['imageUrl'] != null &&
            (data['imageUrl'] as String).isNotEmpty) {
          await deleteImage(data['imageUrl']);
        }
      }

      // Delete document from Firestore
      await _kontenCollection.doc(kontenId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus konten: $e');
    }
  }

  /// Update status konten
  Future<void> updateKontenStatus(String kontenId, String status) async {
    try {
      await _kontenCollection.doc(kontenId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal mengupdate status konten: $e');
    }
  }

  // ========== VIEWS AND LIKES METHODS ==========

  /// Update views count for a konten content
  Future<void> updateViews(String kontenId, int newViewsCount) async {
    try {
      await _kontenCollection.doc(kontenId).update({
        'views': newViewsCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal mengupdate views: $e');
    }
  }

  /// Update likes count for a konten content
  Future<void> updateLikes(String kontenId, int newLikesCount) async {
    try {
      await _kontenCollection.doc(kontenId).update({
        'likes': newLikesCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal mengupdate likes: $e');
    }
  }

  /// Increment views count (atomic operation)
  Future<void> incrementViews(String kontenId) async {
    try {
      await _kontenCollection.doc(kontenId).update({
        'views': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal menambah views: $e');
    }
  }

  /// Increment likes count (atomic operation)
  Future<void> incrementLikes(String kontenId) async {
    try {
      await _kontenCollection.doc(kontenId).update({
        'likes': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal menambah likes: $e');
    }
  }

  /// Decrement likes count (atomic operation)
  Future<void> decrementLikes(String kontenId) async {
    try {
      await _kontenCollection.doc(kontenId).update({
        'likes': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal mengurangi likes: $e');
    }
  }

  /// Toggle like status
  Future<void> toggleLike(String kontenId, bool isLiked) async {
    try {
      if (isLiked) {
        await incrementLikes(kontenId);
      } else {
        await decrementLikes(kontenId);
      }
    } catch (e) {
      throw Exception('Gagal mengupdate like: $e');
    }
  }

  // ========== USER INTERACTION TRACKING ==========

  /// Check if user has liked a specific content
  Future<bool> hasUserLiked(String kontenId, String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('user_likes_konten')
          .doc('${userId}_$kontenId')
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Set user like status
  Future<void> setUserLikeStatus(
    String kontenId,
    String userId,
    bool isLiked,
  ) async {
    try {
      final String docId = '${userId}_$kontenId';

      if (isLiked) {
        await _firestore.collection('user_likes_konten').doc(docId).set({
          'userId': userId,
          'kontenId': kontenId,
          'likedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('user_likes_konten').doc(docId).delete();
      }
    } catch (e) {
      throw Exception('Gagal mengupdate status like user: $e');
    }
  }

  /// Get user's liked content IDs
  Future<List<String>> getUserLikedContentIds(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('user_likes_konten')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['kontenId'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }
}
