import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class CloudinaryService {
  static const String _cloudName = 'de2bfha4g'; // Ganti dengan cloud name Anda
  static const String _apiKey = '429334238539597'; // Ganti dengan API key Anda
  static const String _apiSecret =
      'kDOvGR3oGFtoUdUceLVU20j7AxY'; // Ganti dengan API secret Anda
  static const String _uploadPreset =
      'flutter_products'; // Opsional, jika menggunakan unsigned upload

  final Dio _dio = Dio();

  // Generate signature untuk secure upload/delete
  String _generateSignature(Map<String, dynamic> params, String apiSecret) {
    // Sort parameters by key
    var sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    // Create parameter string (exclude signature itself)
    String paramString = sortedParams.entries
        .where((entry) => entry.key != 'signature' && entry.key != 'api_key')
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    // Add API secret at the end
    paramString += apiSecret;

    print('🔐 Signature string: $paramString'); // Debug log

    // Generate SHA1 hash
    var bytes = utf8.encode(paramString);
    var digest = sha1.convert(bytes);
    return digest.toString();
  }

  // Upload single image to Cloudinary
  Future<String> uploadImage(XFile imageFile, String folder) async {
    try {
      File file = File(imageFile.path);
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${imageFile.name}';

      // Prepare form data
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'upload_preset': _uploadPreset, // Jika menggunakan unsigned upload
        'folder': folder,
        'resource_type': 'image',
        'quality': 'auto:good', // Otomatis optimize kualitas
        'fetch_format': 'auto', // Otomatis pilih format terbaik
      });

      // Upload to Cloudinary
      Response response = await _dio.post(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
        data: formData,
        options: Options(headers: {'Content-Type': 'multipart/form-data'}),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['secure_url']; // Return secure HTTPS URL
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error uploading image to Cloudinary: $e');
      throw Exception('Gagal mengupload gambar: $e');
    }
  }

  // Upload video to Cloudinary
  Future<String> uploadVideo(XFile videoFile, String folder) async {
    try {
      File file = File(videoFile.path);
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${videoFile.name}';

      // Prepare form data for video upload
      FormData formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'upload_preset': _uploadPreset,
        'folder': folder,
        'resource_type': 'video',
      });

      // Upload video to Cloudinary
      Response response = await _dio.post(
        'https://api.cloudinary.com/v1_1/$_cloudName/video/upload',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          sendTimeout: Duration(
            minutes: 10,
          ), // Increase timeout for video upload
          receiveTimeout: Duration(minutes: 10),
        ),
      );

      if (response.statusCode == 200) {
        final responseData = response.data;
        return responseData['secure_url']; // Return secure HTTPS URL
      } else {
        throw Exception('Failed to upload video: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error uploading video to Cloudinary: $e');
      if (e is DioException) {
        print('❌ Dio Error Details: ${e.response?.data}');
      }
      throw Exception('Gagal mengupload video: $e');
    }
  }

  // Upload multiple images to Cloudinary
  Future<List<String>> uploadMultipleImages(
    List<XFile> imageFiles,
    String folder,
  ) async {
    List<String> imageUrls = [];

    try {
      // Upload images concurrently for better performance
      List<Future<String>> uploadFutures = imageFiles.map((imageFile) {
        return uploadImage(imageFile, folder);
      }).toList();

      imageUrls = await Future.wait(uploadFutures);
      return imageUrls;
    } catch (e) {
      print('❌ Error uploading multiple images: $e');
      throw Exception('Gagal mengupload gambar: $e');
    }
  }

  // Delete image from Cloudinary
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract public_id from URL
      String publicId = _extractPublicIdFromUrl(imageUrl, 'image');

      if (publicId.isEmpty) {
        print('⚠️ Could not extract public_id from URL: $imageUrl');
        return;
      }

      print('🗑️ Deleting image with public_id: $publicId');
      await _deleteResource(publicId, 'image');
    } catch (e) {
      print('❌ Error deleting image from Cloudinary: $e');
      // Don't throw error as it's not critical for app functionality
    }
  }

  // Delete video from Cloudinary
  Future<void> deleteVideo(String videoUrl) async {
    try {
      // Extract public_id from URL
      String publicId = _extractPublicIdFromUrl(videoUrl, 'video');

      if (publicId.isEmpty) {
        print('⚠️ Could not extract public_id from video URL: $videoUrl');
        return;
      }

      print('🗑️ Deleting video with public_id: $publicId');
      await _deleteResource(publicId, 'video');
    } catch (e) {
      print('❌ Error deleting video from Cloudinary: $e');
      // Don't throw error as it's not critical for app functionality
    }
  }

  // FIXED: Generic delete resource method with proper authentication
  Future<void> _deleteResource(String publicId, String resourceType) async {
    try {
      // Prepare parameters for deletion with current timestamp
      final timestamp = (DateTime.now().millisecondsSinceEpoch / 1000).floor();

      // Parameters for signature generation (exclude api_key)
      Map<String, dynamic> signatureParams = {
        'public_id': publicId,
        'timestamp': timestamp.toString(),
      };

      // Generate signature
      String signature = _generateSignature(signatureParams, _apiSecret);

      print('🔑 Delete params - Public ID: $publicId, Timestamp: $timestamp');
      print('🔐 Generated signature: $signature');

      // Delete from Cloudinary using Admin API
      FormData formData = FormData.fromMap({
        'public_id': publicId,
        'api_key': _apiKey,
        'timestamp': timestamp,
        'signature': signature,
      });

      // Use the correct endpoint for deletion
      String endpoint;
      if (resourceType == 'video') {
        endpoint = 'https://api.cloudinary.com/v1_1/$_cloudName/video/destroy';
      } else {
        endpoint = 'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy';
      }

      print('🌐 Delete endpoint: $endpoint');

      Response response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
          validateStatus: (status) {
            // Accept both 200 and other success codes
            return status != null && status < 500;
          },
        ),
      );

      print('📡 Delete response status: ${response.statusCode}');
      print('📋 Delete response data: ${response.data}');

      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData['result'] == 'ok') {
          print('✅ $resourceType deleted successfully from Cloudinary');
        } else if (responseData['result'] == 'not found') {
          print(
            '⚠️ $resourceType not found in Cloudinary (may already be deleted)',
          );
        } else {
          print('⚠️ Unexpected delete result: ${responseData['result']}');
        }
      } else {
        print('⚠️ Failed to delete $resourceType: ${response.statusCode}');
        print('📋 Error response: ${response.data}');

        // Handle specific error cases
        if (response.statusCode == 401) {
          print(
            '🔐 Authentication failed - check API credentials and signature',
          );
        } else if (response.statusCode == 404) {
          print('🔍 Resource not found - may already be deleted');
        }
      }
    } catch (e) {
      print('❌ Error deleting $resourceType from Cloudinary: $e');
      if (e is DioException) {
        print(
          '❌ Dio Error Details: ${e.response?.statusCode} - ${e.response?.data}',
        );
        print('❌ Request URL: ${e.requestOptions.uri}');
        print('❌ Request Data: ${e.requestOptions.data}');
      }
    }
  }

  // IMPROVED: Extract public_id from Cloudinary URL with better regex
  String _extractPublicIdFromUrl(String url, String resourceType) {
    try {
      print('🔍 Extracting public_id from URL: $url');

      Uri uri = Uri.parse(url);
      String path = uri.path;

      print('📂 URL path: $path');

      // More flexible regex to handle various URL formats
      // Matches both /image/upload/... and /video/upload/... patterns
      RegExp regex = RegExp(r'/' + resourceType + r'/upload/(?:v\d+/)?(.+)');
      Match? match = regex.firstMatch(path);

      if (match != null) {
        String publicId = match.group(1)!;
        print('🎯 Extracted path: $publicId');

        // Remove file extension if present
        int lastDotIndex = publicId.lastIndexOf('.');
        if (lastDotIndex > 0) {
          publicId = publicId.substring(0, lastDotIndex);
        }

        print('✅ Final public_id: $publicId');
        return publicId;
      }

      print('❌ Could not match regex pattern');
      return '';
    } catch (e) {
      print('❌ Error extracting public_id: $e');
      return '';
    }
  }

  // Get optimized image URL with transformations
  String getOptimizedImageUrl(
    String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto:good',
    String format = 'auto',
  }) {
    try {
      Uri uri = Uri.parse(originalUrl);
      String path = uri.path;

      // Build transformation string
      List<String> transformations = [];
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      transformations.add('q_$quality');
      transformations.add('f_$format');

      String transformationString = transformations.join(',');

      // Insert transformations into URL
      String newPath = path.replaceFirst(
        '/image/upload/',
        '/image/upload/$transformationString/',
      );

      return uri.replace(path: newPath).toString();
    } catch (e) {
      print('❌ Error creating optimized URL: $e');
      return originalUrl; // Return original if transformation fails
    }
  }

  // Get optimized video URL with transformations
  String getOptimizedVideoUrl(
    String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto:good',
    String format = 'mp4',
  }) {
    try {
      Uri uri = Uri.parse(originalUrl);
      String path = uri.path;

      // Build transformation string
      List<String> transformations = [];
      if (width != null) transformations.add('w_$width');
      if (height != null) transformations.add('h_$height');
      transformations.add('q_$quality');
      transformations.add('f_$format');

      String transformationString = transformations.join(',');

      // Insert transformations into URL
      String newPath = path.replaceFirst(
        '/video/upload/',
        '/video/upload/$transformationString/',
      );

      return uri.replace(path: newPath).toString();
    } catch (e) {
      print('❌ Error creating optimized video URL: $e');
      return originalUrl; // Return original if transformation fails
    }
  }

  // ========== IMAGE VALIDATION METHODS ==========

  // Validate image file
  bool isValidImageFile(XFile file) {
    final String extension = file.path.split('.').last.toLowerCase();
    const List<String> allowedExtensions = [
      'jpg',
      'jpeg',
      'png',
      'gif',
      'bmp',
      'webp',
      'svg',
    ];

    return allowedExtensions.contains(extension);
  }

  // Get image file size in MB
  Future<double> getImageFileSize(XFile imageFile) async {
    try {
      final File file = File(imageFile.path);
      final int fileSizeInBytes = await file.length();
      final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      return fileSizeInMB;
    } catch (e) {
      throw Exception('Gagal mendapatkan ukuran file gambar: $e');
    }
  }

  // Validate image file size (default max 10MB for images)
  Future<bool> isValidImageSize(
    XFile imageFile, {
    double maxSizeMB = 10.0,
  }) async {
    try {
      final double fileSizeMB = await getImageFileSize(imageFile);
      return fileSizeMB <= maxSizeMB;
    } catch (e) {
      return false;
    }
  }

  // ========== VIDEO VALIDATION METHODS ==========

  // Validate video file
  bool isValidVideoFile(XFile file) {
    final String extension = file.path.split('.').last.toLowerCase();
    const List<String> allowedExtensions = [
      'mp4',
      'mov',
      'avi',
      'mkv',
      'wmv',
      'webm',
      'flv',
    ];

    return allowedExtensions.contains(extension);
  }

  // Get video file size in MB
  Future<double> getVideoFileSize(XFile videoFile) async {
    try {
      final File file = File(videoFile.path);
      final int fileSizeInBytes = await file.length();
      final double fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      return fileSizeInMB;
    } catch (e) {
      throw Exception('Gagal mendapatkan ukuran file video: $e');
    }
  }

  // Validate video file size (max 100MB)
  Future<bool> isValidVideoSize(
    XFile videoFile, {
    double maxSizeMB = 100.0,
  }) async {
    try {
      final double fileSizeMB = await getVideoFileSize(videoFile);
      return fileSizeMB <= maxSizeMB;
    } catch (e) {
      return false;
    }
  }
}
