import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../models/edukasi.dart';
import 'cloudinary_service.dart';

class EdukasiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  // Collection reference
  CollectionReference get _edukasiCollection =>
      _firestore.collection('edukasi');

  // Get edukasi categories
  List<String> getEdukasiCategories() {
    return [
      'Bisnis',
      'Pemasaran',
      'Keuangan',
      'Teknologi',
      'Pertanian',
      'Kuliner',
      'Fashion',
      'Kesehatan',
      'Pendidikan',
      'Lainnya',
    ];
  }

  // ========== VIDEO AND THUMBNAIL METHODS ==========
  /// Upload video to Cloudinary
  Future<String> uploadVideo(XFile videoFile, String sellerId) async {
    try {
      // Validate video file
      if (!_cloudinaryService.isValidVideoFile(videoFile)) {
        throw Exception('Format video tidak didukung');
      }

      // Check file size (max 100MB)
      if (!await _cloudinaryService.isValidVideoSize(videoFile)) {
        throw Exception('Ukuran video terlalu besar (maksimal 100MB)');
      }

      // Create folder path for videos
      final String folder = 'edukasi/videos/$sellerId';

      // Upload to Cloudinary
      final String videoUrl = await _cloudinaryService.uploadVideo(
        videoFile,
        folder,
      );

      return videoUrl;
    } catch (e) {
      throw Exception('Gagal mengupload video: $e');
    }
  }

  /// Upload custom thumbnail to Cloudinary
  Future<String> uploadThumbnail(XFile thumbnailFile, String sellerId) async {
    try {
      final String folder = 'edukasi/thumbnails/$sellerId';

      // Upload to Cloudinary
      final String thumbnailUrl = await _cloudinaryService.uploadImage(
        thumbnailFile,
        folder,
      );

      return thumbnailUrl;
    } catch (e) {
      throw Exception('Gagal mengupload thumbnail: $e');
    }
  }

  String formatDuration(Duration duration) {
    final int hours = duration.inHours;
    final int minutes = duration.inMinutes.remainder(60);
    final int seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Estimate read time based on video duration
  int calculateReadTime(Duration videoDuration) {
    // Convert to minutes, minimum 1 minute
    return (videoDuration.inSeconds / 60).ceil().clamp(1, 999);
  }

  /// Validate video file
  bool isValidVideoFile(XFile file) {
    return _cloudinaryService.isValidVideoFile(file);
  }

  /// Get video file size in MB
  Future<double> getVideoFileSize(XFile videoFile) async {
    try {
      return await _cloudinaryService.getVideoFileSize(videoFile);
    } catch (e) {
      throw Exception('Gagal mendapatkan ukuran file video: $e');
    }
  }

  /// Validate video file size
  Future<bool> isValidVideoSize(
    XFile videoFile, {
    double maxSizeMB = 100.0,
  }) async {
    try {
      return await _cloudinaryService.isValidVideoSize(
        videoFile,
        maxSizeMB: maxSizeMB,
      );
    } catch (e) {
      return false;
    }
  }

  /// Delete thumbnail from Cloudinary
  Future<void> deleteThumbnail(String thumbnailUrl) async {
    try {
      await _cloudinaryService.deleteImage(thumbnailUrl);
    } catch (e) {
      print('⚠️ Error deleting thumbnail: $e');
      // Don't throw error as it's not critical
    }
  }

  /// Delete video from Cloudinary
  Future<void> deleteVideo(String videoUrl) async {
    try {
      await _cloudinaryService.deleteVideo(videoUrl);
    } catch (e) {
      print('⚠️ Error deleting video: $e');
      // Don't throw error as it's not critical
    }
  }

  /// Get optimized video URL with transformations
  String getOptimizedVideoUrl(
    String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto:good',
    String format = 'mp4',
  }) {
    return _cloudinaryService.getOptimizedVideoUrl(
      originalUrl,
      width: width,
      height: height,
      quality: quality,
      format: format,
    );
  }

  // ========== FIRESTORE CRUD METHODS ==========

  /// Add new edukasi to Firestore
  Future<void> addEdukasi(EdukasiModel edukasi) async {
    try {
      // Add to Firestore (auto-generate ID)
      final DocumentReference docRef = await _edukasiCollection.add(
        edukasi.toJson(),
      );

      // Update with the generated ID
      await docRef.update({'id': docRef.id});
    } catch (e) {
      throw Exception('Gagal menambahkan konten edukasi: $e');
    }
  }

  /// Get all edukasi content
  Future<List<EdukasiModel>> getAllEdukasi() async {
    try {
      final QuerySnapshot snapshot = await _edukasiCollection
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => EdukasiModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data edukasi: $e');
    }
  }

  /// Get edukasi by seller ID
  Future<List<EdukasiModel>> getEdukasiBySeller(String sellerId) async {
    try {
      final QuerySnapshot snapshot = await _edukasiCollection
          .where('sellerId', isEqualTo: sellerId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => EdukasiModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data edukasi seller: $e');
    }
  }

  /// Get edukasi by category
  Future<List<EdukasiModel>> getEdukasiByCategory(String category) async {
    try {
      final QuerySnapshot snapshot = await _edukasiCollection
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'Published')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => EdukasiModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data edukasi kategori: $e');
    }
  }

  /// Get published edukasi only
  Future<List<EdukasiModel>> getPublishedEdukasi() async {
    try {
      final QuerySnapshot snapshot = await _edukasiCollection
          .where('status', isEqualTo: 'Published')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map(
            (doc) => EdukasiModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('Gagal mengambil data edukasi published: $e');
    }
  }

  /// Update edukasi
  Future<void> updateEdukasi(EdukasiModel edukasi) async {
    try {
      await _edukasiCollection.doc(edukasi.uid).update(edukasi.toJson());
    } catch (e) {
      throw Exception('Gagal mengupdate konten edukasi: $e');
    }
  }

  /// Delete edukasi (with media cleanup)
  Future<void> deleteEdukasi(String edukasiId) async {
    try {
      // Get edukasi data first to clean up media files
      final DocumentSnapshot doc = await _edukasiCollection
          .doc(edukasiId)
          .get();

      print('apakah doc ${doc.id}');

      if (doc.exists) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        // Delete video from Cloudinary if exists
        if (data['videoUrl'] != null &&
            (data['videoUrl'] as String).isNotEmpty) {
          await deleteVideo(data['videoUrl']);
        }

        // Delete thumbnail from Cloudinary if exists
        if (data['thumbnailUrl'] != null &&
            (data['thumbnailUrl'] as String).isNotEmpty) {
          await deleteThumbnail(data['thumbnailUrl']);
        }
      }

      // Delete document from Firestore
      await _edukasiCollection.doc(edukasiId).delete();
    } catch (e) {
      throw Exception('Gagal menghapus konten edukasi: $e');
    }
  }

  /// Update status edukasi
  Future<void> updateEdukasiStatus(String edukasiId, String status) async {
    try {
      await _edukasiCollection.doc(edukasiId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal mengupdate status edukasi: $e');
    }
  }

  // ========== VIEWS AND LIKES METHODS ==========

  /// Update views count for an edukasi content
  Future<void> updateViews(String edukasiId, int newViewsCount) async {
    try {
      await _edukasiCollection.doc(edukasiId).update({
        'views': newViewsCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal mengupdate views: $e');
    }
  }

  /// Update likes count for an edukasi content
  Future<void> updateLikes(String edukasiId, int newLikesCount) async {
    try {
      await _edukasiCollection.doc(edukasiId).update({
        'likes': newLikesCount,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal mengupdate likes: $e');
    }
  }

  /// Increment views count (atomic operation)
  Future<void> incrementViews(String edukasiId) async {
    try {
      await _edukasiCollection.doc(edukasiId).update({
        'views': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal menambah views: $e');
    }
  }

  /// Increment likes count (atomic operation)
  Future<void> incrementLikes(String edukasiId) async {
    try {
      await _edukasiCollection.doc(edukasiId).update({
        'likes': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal menambah likes: $e');
    }
  }

  /// Decrement likes count (atomic operation)
  Future<void> decrementLikes(String edukasiId) async {
    try {
      await _edukasiCollection.doc(edukasiId).update({
        'likes': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Gagal mengurangi likes: $e');
    }
  }

  /// Toggle like status
  Future<void> toggleLike(String edukasiId, bool isLiked) async {
    try {
      if (isLiked) {
        await incrementLikes(edukasiId);
      } else {
        await decrementLikes(edukasiId);
      }
    } catch (e) {
      throw Exception('Gagal mengupdate like: $e');
    }
  }

  // ========== USER INTERACTION TRACKING ==========

  /// Check if user has liked a specific content
  Future<bool> hasUserLiked(String edukasiId, String userId) async {
    try {
      final DocumentSnapshot doc = await _firestore
          .collection('user_likes')
          .doc('${userId}_$edukasiId')
          .get();

      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Set user like status
  Future<void> setUserLikeStatus(
    String edukasiId,
    String userId,
    bool isLiked,
  ) async {
    try {
      final String docId = '${userId}_$edukasiId';

      if (isLiked) {
        await _firestore.collection('user_likes').doc(docId).set({
          'userId': userId,
          'edukasiId': edukasiId,
          'likedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _firestore.collection('user_likes').doc(docId).delete();
      }
    } catch (e) {
      throw Exception('Gagal mengupdate status like user: $e');
    }
  }

  /// Get user's liked content IDs
  Future<List<String>> getUserLikedContentIds(String userId) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('user_likes')
          .where('userId', isEqualTo: userId)
          .get();

      return snapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .map((data) => data['edukasiId'] as String)
          .toList();
    } catch (e) {
      return [];
    }
  }
}
