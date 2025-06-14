import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:smart/models/edukasi.dart';
import 'package:smart/services/edukasi_service.dart';
import 'package:smart/utils/snackbar_helper.dart';
import 'dart:io';

class EditEdukasiScreen extends StatefulWidget {
  final EdukasiModel edukasi;
  final String sellerId;
  final String namaToko;

  const EditEdukasiScreen({
    Key? key,
    required this.edukasi,
    required this.sellerId,
    required this.namaToko,
  }) : super(key: key);

  @override
  State<EditEdukasiScreen> createState() => _EditEdukasiScreenState();
}

class _EditEdukasiScreenState extends State<EditEdukasiScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isPreviewLoading = false;
  String _selectedCategory = 'Makanan Utama';
  String _selectedStatus = 'Draft';

  // Media files
  XFile? _videoFile;
  XFile? _thumbnailFile;
  VideoPlayerController? _videoController;

  // Current media URLs (from existing edukasi)
  String? _currentVideoUrl;
  String? _currentThumbnailUrl;

  // Services
  final EdukasiService _edukasiService = EdukasiService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Initialize form with existing data
    _titleController.text = widget.edukasi.title;
    _descriptionController.text = widget.edukasi.description;
    _selectedCategory = widget.edukasi.category;
    _selectedStatus = widget.edukasi.status;
    _currentVideoUrl = widget.edukasi.videoUrl;
    _currentThumbnailUrl = widget.edukasi.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  // Pick video from gallery
  Future<void> _pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 10),
      );

      if (video != null) {
        setState(() {
          _isPreviewLoading = true;
        });

        // Validate video file
        if (!_edukasiService.isValidVideoFile(video)) {
          throw Exception('Format video tidak didukung');
        }

        // Check video size
        if (!await _edukasiService.isValidVideoSize(video)) {
          throw Exception('Ukuran video terlalu besar (maksimal 100MB)');
        }

        // Dispose previous controller
        _videoController?.dispose();

        // Initialize new video controller
        _videoController = VideoPlayerController.file(File(video.path));
        await _videoController!.initialize();

        setState(() {
          _videoFile = video;
          _isPreviewLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isPreviewLoading = false;
      });

      if (mounted) {
        SnackbarHelper.showErrorSnackbar(context, 'Error memilih video: $e');
      }
    }
  }

  // Pick custom thumbnail
  Future<void> _pickThumbnail() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _thumbnailFile = image;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackbar(
          context,
          'Error memilih thumbnail: $e',
        );
      }
    }
  }

  // Update edukasi
  Future<void> _updateEdukasi() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? videoUrl = _currentVideoUrl;
      String? thumbnailUrl = _currentThumbnailUrl;

      // Upload new video if selected
      if (_videoFile != null) {
        videoUrl = await _edukasiService.uploadVideo(
          _videoFile!,
          widget.sellerId,
        );
      }

      // Upload new thumbnail if selected
      if (_thumbnailFile != null) {
        thumbnailUrl = await _edukasiService.uploadThumbnail(
          _thumbnailFile!,
          widget.sellerId,
        );
      }

      // Calculate read time based on video duration or keep existing
      int readTime = widget.edukasi.readTime;
      if (_videoController != null) {
        readTime = _edukasiService.calculateReadTime(
          _videoController!.value.duration,
        );
      }

      // Create updated edukasi model
      final updatedEdukasi = EdukasiModel(
        id: widget.edukasi.id,
        uid: widget.edukasi.uid,
        sellerId: widget.sellerId,
        namaToko: widget.namaToko,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        videoUrl: videoUrl!,
        imageUrl: widget.edukasi.imageUrl,
        readTime: readTime,
        views: widget.edukasi.views,
        likes: widget.edukasi.likes,
        status: _selectedStatus,
        createdAt: widget.edukasi.createdAt,
      );

      // Update in Firebase
      await _edukasiService.updateEdukasi(updatedEdukasi);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        SnackbarHelper.showSuccessSnackbar(
          context,
          'Konten edukasi berhasil diperbarui',
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        SnackbarHelper.showErrorSnackbar(
          context,
          'Gagal memperbarui konten edukasi: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
        ),
        title: const Text(
          'Edit Konten Edukasi',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateEdukasi,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF4DA8DA),
                      ),
                    ),
                  )
                : const Text(
                    'Simpan',
                    style: TextStyle(
                      color: Color(0xFF4DA8DA),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              _buildFormField(
                label: 'Judul Konten',
                child: TextFormField(
                  controller: _titleController,
                  decoration: _inputDecoration('Masukkan judul konten edukasi'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Judul tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Description Field
              _buildFormField(
                label: 'Deskripsi',
                child: TextFormField(
                  controller: _descriptionController,
                  decoration: _inputDecoration('Jelaskan konten edukasi Anda'),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Deskripsi tidak boleh kosong';
                    }
                    return null;
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Category Dropdown
              _buildFormField(
                label: 'Kategori',
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: _inputDecoration('Pilih kategori'),
                  items: _edukasiService
                      .getEdukasiCategories()
                      .where((category) => category != 'Semua')
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Status Dropdown
              _buildFormField(
                label: 'Status',
                child: DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  decoration: _inputDecoration('Pilih status'),
                  items: ['Draft', 'Published']
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(status),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value!;
                    });
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Video Section
              _buildFormField(
                label: 'Video Konten',
                child: Column(
                  children: [
                    // Current video preview or new video preview
                    if (_videoFile != null && _videoController != null)
                      _buildVideoPreview()
                    else if (_currentVideoUrl != null)
                      _buildCurrentVideoInfo(),

                    const SizedBox(height: 12),

                    // Pick video button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _pickVideo,
                        icon: const Icon(Icons.video_library),
                        label: Text(
                          _videoFile != null || _currentVideoUrl != null
                              ? 'Ganti Video'
                              : 'Pilih Video',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4DA8DA),
                          side: const BorderSide(color: Color(0xFF4DA8DA)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Thumbnail Section
              _buildFormField(
                label: 'Thumbnail (Opsional)',
                child: Column(
                  children: [
                    // Current thumbnail or new thumbnail preview
                    if (_thumbnailFile != null)
                      _buildThumbnailPreview()
                    else if (_currentThumbnailUrl != null)
                      _buildCurrentThumbnailInfo(),

                    const SizedBox(height: 12),

                    // Pick thumbnail button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _pickThumbnail,
                        icon: const Icon(Icons.image),
                        label: Text(
                          _thumbnailFile != null || _currentThumbnailUrl != null
                              ? 'Ganti Thumbnail'
                              : 'Pilih Thumbnail',
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF4DA8DA),
                          side: const BorderSide(color: Color(0xFF4DA8DA)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
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
                  onPressed: _isLoading ? null : _updateEdukasi,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4DA8DA),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Memperbarui...'),
                          ],
                        )
                      : const Text(
                          'Perbarui Konten Edukasi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[500]),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF4DA8DA)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
      contentPadding: const EdgeInsets.all(16),
    );
  }

  Widget _buildVideoPreview() {
    if (_isPreviewLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFF4DA8DA)),
        ),
      );
    }

    if (_videoController != null && _videoController!.value.isInitialized) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
              Center(
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      if (_videoController!.value.isPlaying) {
                        _videoController!.pause();
                      } else {
                        _videoController!.play();
                      }
                    });
                  },
                  icon: Icon(
                    _videoController!.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _edukasiService.formatDuration(
                      _videoController!.value.duration,
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildCurrentVideoInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.video_library, color: Colors.blue[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Video saat ini',
                  style: TextStyle(
                    color: Colors.blue[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Video telah diupload sebelumnya',
                  style: TextStyle(color: Colors.blue[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailPreview() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(_thumbnailFile!.path), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildCurrentThumbnailInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.image, color: Colors.green[600], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thumbnail saat ini',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Thumbnail telah diupload sebelumnya',
                  style: TextStyle(color: Colors.green[600], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
