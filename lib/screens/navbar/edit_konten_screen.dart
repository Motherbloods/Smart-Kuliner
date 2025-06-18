import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart/models/konten.dart';
import 'package:smart/services/konten_service.dart';
import 'package:smart/utils/snackbar_helper.dart';
import 'dart:io';

class EditKontenScreen extends StatefulWidget {
  final KontenModel konten;
  final String sellerId;
  final String namaToko;

  const EditKontenScreen({
    Key? key,
    required this.konten,
    required this.sellerId,
    required this.namaToko,
  }) : super(key: key);

  @override
  State<EditKontenScreen> createState() => _EditKontenScreenState();
}

class _EditKontenScreenState extends State<EditKontenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  bool _isPreviewLoading = false;
  String _selectedCategory = 'Makanan Utama';
  String _selectedStatus = 'Draft';

  XFile? _imageFile;

  String? _currentImageURL;

  // Services
  final KontenService _kontenService = KontenService();
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    // Initialize form with existing data
    _titleController.text = widget.konten.title;
    _descriptionController.text = widget.konten.description;
    _selectedCategory = widget.konten.category;
    _selectedStatus = widget.konten.status;
    _currentImageURL = widget.konten.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // Pick custom thumbnail
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1080,
      );

      if (image != null) {
        setState(() {
          _imageFile = image;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackbar(context, 'Error memilih Image: $e');
      }
    }
  }

  // Update edukasi
  Future<void> _updateKonten() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = _currentImageURL;

      // Upload new thumbnail if selected
      if (_imageFile != null) {
        imageUrl = await _kontenService.uploadImage(
          _imageFile!,
          widget.sellerId,
        );
      }

      // Create updated edukasi model
      final updatedEdukasi = KontenModel(
        id: widget.konten.id,
        sellerId: widget.sellerId,
        namaToko: widget.namaToko,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        imageUrl: imageUrl!, // Use the updated imageUrl
        views: widget.konten.views!,
        likes: widget.konten.likes!,
        status: _selectedStatus,
        createdAt: widget.konten.createdAt,
      );

      // Update in Firebase
      await _kontenService.updateKonten(updatedEdukasi);

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        SnackbarHelper.showSuccessSnackbar(
          context,
          'Konten promosi berhasil diperbarui',
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
          'Gagal memperbarui konten promosi: $e',
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
          'Edit Konten Promosi',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateKonten,
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
              // Current Image Preview Section (moved to top)
              if (_currentImageURL != null || _imageFile != null) ...[
                _buildFormField(
                  label: 'Gambar Konten Saat Ini',
                  child: Column(
                    children: [
                      _buildCurrentImagePreview(),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text('Ganti Gambar'),
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
              ],

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
                  items: _kontenService
                      .getKontenCategories()
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

              // If no image exists, show upload button
              if (_currentImageURL == null && _imageFile == null) ...[
                _buildFormField(
                  label: 'Gambar Konten',
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _pickImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Pilih Gambar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF4DA8DA),
                        side: const BorderSide(color: Color(0xFF4DA8DA)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateKonten,
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
                          'Perbarui Konten Promosi',
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

  Widget _buildCurrentImagePreview() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _imageFile != null
                ? Image.file(
                    File(_imageFile!.path),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  )
                : (_currentImageURL != null
                      ? Image.network(
                          _currentImageURL!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              alignment: Alignment.center,
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF4DA8DA),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              alignment: Alignment.center,
                              color: Colors.grey[200],
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    size: 48,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Gagal memuat gambar',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        )
                      : Container(
                          alignment: Alignment.center,
                          color: Colors.grey[200],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tidak ada gambar',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )),
          ),
          // Overlay label
          if (_imageFile != null)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Gambar Baru',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(File(_imageFile!.path), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildCurrentImageInfo() {
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
                  'Konten saat ini',
                  style: TextStyle(
                    color: Colors.green[800],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Image telah diupload sebelumnya',
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
