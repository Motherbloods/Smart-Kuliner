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

  // Generate signature untuk secure upload (opsional)
  String _generateSignature(Map<String, dynamic> params, String apiSecret) {
    // Sort parameters
    var sortedParams = Map.fromEntries(
      params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    // Create parameter string
    String paramString = sortedParams.entries
        .map((entry) => '${entry.key}=${entry.value}')
        .join('&');

    // Add API secret
    paramString += apiSecret;

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

      // If using signed upload (more secure)
      // Uncomment dan sesuaikan jika ingin menggunakan signed upload
      /*
      int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      Map<String, dynamic> params = {
        'timestamp': timestamp,
        'folder': folder,
        'resource_type': 'image',
      };
      
      String signature = _generateSignature(params, _apiSecret);
      
      formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
        'api_key': _apiKey,
        'timestamp': timestamp,
        'signature': signature,
        'folder': folder,
        'resource_type': 'image',
        'quality': 'auto:good',
        'fetch_format': 'auto',
      });
      */

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
      String publicId = _extractPublicIdFromUrl(imageUrl);

      if (publicId.isEmpty) {
        print('⚠️ Could not extract public_id from URL: $imageUrl');
        return;
      }

      // Prepare parameters for deletion
      int timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      Map<String, dynamic> params = {
        'public_id': publicId,
        'timestamp': timestamp,
      };

      String signature = _generateSignature(params, _apiSecret);

      // Delete from Cloudinary
      FormData formData = FormData.fromMap({
        'public_id': publicId,
        'api_key': _apiKey,
        'timestamp': timestamp,
        'signature': signature,
      });

      Response response = await _dio.post(
        'https://api.cloudinary.com/v1_1/$_cloudName/image/destroy',
        data: formData,
      );

      if (response.statusCode == 200) {
        print('✅ Image deleted successfully from Cloudinary');
      } else {
        print('⚠️ Failed to delete image: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error deleting image from Cloudinary: $e');
      // Don't throw error as it's not critical for app functionality
    }
  }

  // Extract public_id from Cloudinary URL
  String _extractPublicIdFromUrl(String url) {
    try {
      Uri uri = Uri.parse(url);
      String path = uri.path;

      // Remove /v1_1/cloud_name/image/upload/ or /v1_1/cloud_name/image/upload/transformations/
      RegExp regex = RegExp(r'/v1_1/[^/]+/image/upload/(?:v\d+/)?(.+)');
      Match? match = regex.firstMatch(path);

      if (match != null) {
        String publicId = match.group(1)!;
        // Remove file extension
        int lastDotIndex = publicId.lastIndexOf('.');
        if (lastDotIndex > 0) {
          publicId = publicId.substring(0, lastDotIndex);
        }
        return publicId;
      }

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
}
