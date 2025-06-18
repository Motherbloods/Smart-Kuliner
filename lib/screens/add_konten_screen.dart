import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart/models/konten.dart';
import 'package:smart/services/konten_service.dart';
import 'package:smart/utils/capitalize_text.dart';
import 'package:smart/utils/image_picker_service.dart';
import 'package:smart/utils/snackbar_helper.dart';
import 'package:smart/widgets/section_card.dart';
import 'dart:io';

class AddKontenScreen extends StatefulWidget {
  final String sellerId;
  final String namaToko;

  const AddKontenScreen({
    Key? key,
    required this.sellerId,
    required this.namaToko,
  }) : super(key: key);

  @override
  State<AddKontenScreen> createState() => _AddKontenScreenState();
}

class _AddKontenScreenState extends State<AddKontenScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  final KontenService _kontenService = KontenService();
  final ImagePickerService _imagePickerService = ImagePickerService();

  String _selectedCategory = 'Semua';
  XFile? _selectedImage;
  bool _isLoading = false;

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _categories = _kontenService.getKontenCategories();
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final image = await _imagePickerService.pickSingleImage();

      if (image == null) return;

      setState(() {
        _selectedImage = image;
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

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  Future<void> _saveKonten() async {
    if (!_formKey.currentState!.validate()) {
      print('Form tidak valid');
      return;
    }

    if (_selectedImage == null) {
      print('Gambar belum dipilih');
      SnackbarHelper.showErrorSnackbar(context, 'Pilih gambar terlebih dahulu');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('--- MULAI PROSES UPLOAD ---');

      // Upload thumbnail
      print('Upload thumbnail...');
      String thumbnailUrl = await _kontenService.uploadImage(
        _selectedImage!,
        widget.sellerId,
      );
      print('Thumbnail URL: $thumbnailUrl');

      KontenModel newKonten = KontenModel(
        id: 'video ke ${DateTime.now()}',
        sellerId: widget.sellerId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrl: thumbnailUrl,
        category: _selectedCategory,
        createdAt: DateTime.now(),
        status: 'Published',
        namaToko: widget.namaToko,
      );

      print('Data Edukasi yang akan disimpan: ${newKonten.toJson()}');

      await _kontenService.addKonten(newKonten);

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
          'Tambah Konten Promosi',
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
                    // Thumbnail Section
                    SectionCard(
                      title: 'Gambar Konten',
                      child: Column(
                        children: [
                          if (_selectedImage == null)
                            GestureDetector(
                              onTap: _pickImage,
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
                                      'Pilih Konten *',
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
                                    File(_selectedImage!.path),
                                    height: 120,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: GestureDetector(
                                    onTap: _removeImage,
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
                          if (_selectedImage != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickImage,
                                    icon: const Icon(Icons.image),
                                    label: const Text('Ganti Konten'),
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
                              hintText: 'Masukkan judul konten',
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
                                  'Deskripsikan konten Anda dengan detail',
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveKonten,
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
                          'Simpan Konten Promosi',
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
