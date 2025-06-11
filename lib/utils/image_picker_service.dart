import 'package:image_picker/image_picker.dart';

class ImagePickerService {
  final ImagePicker _imagePicker = ImagePicker();

  Future<List<XFile>?> pickMultipleImages() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return images;
    } catch (e) {
      throw Exception('Gagal memilih gambar: $e');
    }
  }

  /// Pick a single image
  Future<XFile?> pickSingleImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      return image;
    } catch (e) {
      throw Exception('Gagal memilih gambar: $e');
    }
  }

  /// Pick a video
  Future<XFile?> pickVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );
      return video;
    } catch (e) {
      throw Exception('Gagal memilih video: $e');
    }
  }
}
