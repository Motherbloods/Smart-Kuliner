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
      // Bisa juga throw error supaya di-handle di UI
      throw Exception('Gagal memilih gambar: $e');
    }
  }
}
