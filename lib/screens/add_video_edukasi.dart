import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart/utils/capitalize_text.dart';
import 'package:smart/utils/image_picker_service.dart';
import 'package:smart/utils/snackbar_helper.dart';
import 'package:smart/widgets/section_card.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import '../../services/edukasi_service.dart';
import '../../models/edukasi.dart';

class AddEdukasiScreen extends StatefulWidget {
  final String sellerId;
  final String namaToko;

  const AddEdukasiScreen({
    Key? key,
    required this.sellerId,
    required this.namaToko,
  }) : super(key: key);

  @override
  State<AddEdukasiScreen> createState() => _AddEdukasiScreenState();
}

class _AddEdukasiScreenState extends State<AddEdukasiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final EdukasiService _edukasiService = EdukasiService();
  final ImagePickerService _imagePickerService = ImagePickerService();

  String _selectedCategory = 'Bisnis';
  XFile? _selectedVideo;
  XFile? _selectedThumbnail;
  VideoPlayerController? _videoController;
  bool _isLoading = false;
  int _videoDuration = 0; // in seconds

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _categories = _edukasiService.getEdukasiCategories();
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo() async {
    try {
      final video = await _imagePickerService.pickVideo();

      if (video == null) return;

      // Dispose previous controller
      _videoController?.dispose();

      // Create new video controller
      _videoController = VideoPlayerController.file(File(video.path));
      await _videoController!.initialize();

      // Get video duration
      final duration = _videoController!.value.duration;
      final durationInSeconds = duration.inSeconds;
      setState(() {
        _selectedVideo = video;
        _videoDuration = durationInSeconds;
      });
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackbar(context, 'Gagal memilih video: $e');
      }
    }
  }

  Future<void> _pickThumbnail() async {
    try {
      final image = await _imagePickerService.pickSingleImage();

      if (image == null) return;

      setState(() {
        _selectedThumbnail = image;
      });
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackbar(
          context,
          'Gagal memilih thumbnail: $e',
        );
      }
    }
  }

  void _removeVideo() {
    setState(() {
      _selectedVideo = null;
      _selectedThumbnail = null;
      _videoDuration = 0;
    });
    _videoController?.dispose();
    _videoController = null;
  }

  void _removeThumbnail() {
    setState(() {
      _selectedThumbnail = null;
    });
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  int _calculateReadTime(int videoDurationSeconds) {
    // Convert seconds to minutes, minimum 1 minute
    return (videoDurationSeconds / 60).ceil().clamp(1, 999);
  }

  Future<void> _saveEdukasi() async {
    if (!_formKey.currentState!.validate()) {
      print('Form tidak valid');
      return;
    }

    if (_selectedVideo == null) {
      print('Video belum dipilih');
      SnackbarHelper.showErrorSnackbar(
        context,
        'Pilih video edukasi terlebih dahulu',
      );
      return;
    }

    if (_selectedThumbnail == null) {
      print('Thumbnail belum dipilih');
      SnackbarHelper.showErrorSnackbar(
        context,
        'Pilih thumbnail video terlebih dahulu',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('--- MULAI PROSES UPLOAD ---');

      // Upload video
      print('Mengupload video...');
      String videoUrl = await _edukasiService.uploadVideo(
        _selectedVideo!,
        widget.sellerId,
      );
      print('Video URL: $videoUrl');

      // Upload thumbnail
      print('Upload thumbnail...');
      String thumbnailUrl = await _edukasiService.uploadThumbnail(
        _selectedThumbnail!,
        widget.sellerId,
      );
      print('Thumbnail URL: $thumbnailUrl');

      // Create edukasi content
      final readTime = _calculateReadTime(_videoDuration);
      print('Waktu baca (estimasi): $readTime detik');

      EdukasiModel newEdukasi = EdukasiModel(
        uid: 'video ke ${DateTime.now()}',
        sellerId: widget.sellerId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        videoUrl: videoUrl,
        imageUrl: thumbnailUrl,
        category: _selectedCategory,
        readTime: readTime,
        createdAt: DateTime.now(),
        status: 'Published',
        namaToko: widget.namaToko,
      );

      print('Data Edukasi yang akan disimpan: ${newEdukasi.toJson()}');

      await _edukasiService.addEdukasi(newEdukasi);

      if (mounted) {
        SnackbarHelper.showSuccessSnackbar(
          context,
          'Konten edukasi berhasil ditambahkan!',
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      print('Terjadi error saat menyimpan edukasi: $e');
      if (mounted) {
        SnackbarHelper.showErrorSnackbar(
          context,
          'Gagal menambahkan konten edukasi: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      print('--- SELESAI ---');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tambah Konten Edukasi',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF4DA8DA),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4DA8DA)),
                  SizedBox(height: 16),
                  Text(
                    'Menyimpan konten edukasi...',
                    style: TextStyle(color: Color(0xFF4A5568), fontSize: 16),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video Section
                    SectionCard(
                      title: 'Video Edukasi',
                      child: Column(
                        children: [
                          if (_selectedVideo == null)
                            GestureDetector(
                              onTap: _pickVideo,
                              child: Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.video_library,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Pilih Video Edukasi',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Format: MP4, MOV, AVI',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Column(
                              children: [
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Stack(
                                    children: [
                                      if (_videoController != null &&
                                          _videoController!.value.isInitialized)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: AspectRatio(
                                            aspectRatio: _videoController!
                                                .value
                                                .aspectRatio,
                                            child: VideoPlayer(
                                              _videoController!,
                                            ),
                                          ),
                                        )
                                      else
                                        const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF4DA8DA),
                                          ),
                                        ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: _removeVideo,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 8,
                                        left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.7,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            'Durasi: ${_formatDuration(_videoDuration)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: _pickVideo,
                                        icon: const Icon(Icons.video_library),
                                        label: const Text('Ganti Video'),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                          ),
                                          side: const BorderSide(
                                            color: Color(0xFF4DA8DA),
                                          ),
                                          foregroundColor: const Color(
                                            0xFFFF6B35,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Thumbnail Section
                    SectionCard(
                      title: 'Thumbnail Video',
                      child: Column(
                        children: [
                          if (_selectedThumbnail == null)
                            GestureDetector(
                              onTap: _pickThumbnail,
                              child: Container(
                                height: 120,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey[300]!,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      size: 32,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pilih Thumbnail *',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Format: JPG, PNG',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    File(_selectedThumbnail!.path),
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: _removeThumbnail,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (_selectedThumbnail != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickThumbnail,
                                    icon: const Icon(Icons.image),
                                    label: const Text('Ganti Thumbnail'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      side: const BorderSide(
                                        color: Color(0xFF4DA8DA),
                                      ),
                                      foregroundColor: const Color(0xFF4DA8DA),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Content Information Section
                    SectionCard(
                      title: 'Informasi Konten',
                      child: Column(
                        children: [
                          // Title
                          TextFormField(
                            controller: _titleController,
                            onChanged: (value) {
                              final formatted = capitalizeEachWord(value);
                              if (value != formatted) {
                                _titleController.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(
                                    offset: formatted.length,
                                  ),
                                );
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Judul Konten *',
                              hintText: 'Masukkan judul konten edukasi',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4DA8DA),
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Judul konten harus diisi';
                              }
                              if (value.trim().length < 5) {
                                return 'Judul konten minimal 5 karakter';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Category
                          DropdownButtonFormField<String>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Kategori *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4DA8DA),
                                ),
                              ),
                            ),
                            items: _categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 4,
                            onChanged: (value) {
                              final formatted = capitalizeEachWord(value);
                              if (value != formatted) {
                                _descriptionController.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(
                                    offset: formatted.length,
                                  ),
                                );
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Deskripsi Konten *',
                              hintText:
                                  'Deskripsikan konten edukasi Anda dengan detail',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF4DA8DA),
                                ),
                              ),
                              alignLabelWithHint: true,
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Deskripsi konten harus diisi';
                              }
                              if (value.trim().length < 10) {
                                return 'Deskripsi minimal 10 karakter';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Read Time Display
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.schedule,
                                  color: Colors.blue[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Durasi Tontonan: ${_calculateReadTime(_videoDuration)} menit',
                                  style: TextStyle(
                                    color: Colors.blue[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveEdukasi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4DA8DA),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Simpan Konten Edukasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}
