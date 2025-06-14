import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart/utils/capitalize_text.dart';
import 'package:smart/utils/image_picker_service.dart';
import 'package:smart/utils/snackbar_helper.dart';
import 'package:smart/widgets/section_card.dart';
import 'dart:io';
import '../../services/product_service.dart';
import '../../models/product.dart';

class AddProductScreen extends StatefulWidget {
  final String sellerId;
  final String nameToko;

  const AddProductScreen({
    Key? key,
    required this.sellerId,
    required this.nameToko,
  }) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameProdukController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  final ProductService _productService = ProductService();
  final ImagePickerService _imagePickerService = ImagePickerService();

  String _selectedCategory = 'Elektronik';
  List<XFile> _selectedImages = [];
  bool _isLoading = false;

  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _categories = _productService.getProductCategories();
    _selectedCategory = _categories.first;
  }

  @override
  void dispose() {
    _nameProdukController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final images = await _imagePickerService.pickMultipleImages();

      if (images == null || images.isEmpty) return;

      if (images.length > 5) {
        if (mounted) {
          SnackbarHelper.showErrorSnackbar(
            context,
            'Maksimal 5 gambar yang dapat dipilih',
          );
        }
        return;
      }

      setState(() {
        _selectedImages = images;
      });
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackbar(context, 'Gagal memilih gambar: $e');
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImages.isEmpty) {
      SnackbarHelper.showErrorSnackbar(
        context,
        'Pilih minimal 1 gambar produk',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload images
      List<String> imageUrls = await _productService.uploadProductImages(
        _selectedImages,
        widget.sellerId,
      );

      // Create product
      ProductModel newProduct = ProductModel(
        id: '',
        sellerId: widget.sellerId,
        name: _nameProdukController.text.trim(),
        description: _descriptionController.text.trim(),
        nameToko: widget.nameToko,
        price: double.parse(_priceController.text),
        category: _selectedCategory,
        imageUrls: imageUrls,
        stock: int.parse(_stockController.text),
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _productService.addProduct(newProduct);

      if (mounted) {
        SnackbarHelper.showSuccessSnackbar(
          context,
          'Produk berhasil ditambahkan!',
        );
        Navigator.pop(
          context,
          true,
        ); // Return true to indicate product was added
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showErrorSnackbar(
          context,
          'Gagal menambahkan produk: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Tambah Produk',
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
                    'Menyimpan produk...',
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
                    // Product Images Section
                    SectionCard(
                      title: 'Gambar Produk',
                      child: Column(
                        children: [
                          if (_selectedImages.isEmpty)
                            GestureDetector(
                              onTap: _pickImages,
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
                                      Icons.add_photo_alternate,
                                      size: 48,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Pilih Gambar Produk',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      'Maksimal 5 gambar',
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
                                SizedBox(
                                  height: 120,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _selectedImages.length,
                                    itemBuilder: (context, index) {
                                      return Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.file(
                                                File(
                                                  _selectedImages[index].path,
                                                ),
                                                width: 120,
                                                height: 120,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () =>
                                                    _removeImage(index),
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration:
                                                      const BoxDecoration(
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
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (_selectedImages.length < 5)
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _pickImages,
                                      icon: const Icon(
                                        Icons.add_photo_alternate,
                                      ),
                                      label: Text(
                                        'Tambah Gambar (${_selectedImages.length}/5)',
                                      ),
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
                    ),

                    const SizedBox(height: 16),

                    // Product Information Section
                    SectionCard(
                      title: 'Informasi Produk',
                      child: Column(
                        children: [
                          // Product Name
                          TextFormField(
                            controller: _nameProdukController,
                            onChanged: (value) {
                              final formatted = capitalizeEachWord(value);
                              if (value != formatted) {
                                _nameProdukController.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(
                                    offset: formatted.length,
                                  ),
                                );
                              }
                            },
                            decoration: InputDecoration(
                              labelText: 'Nama Produk *',
                              hintText: 'Masukkan nama produk',
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
                                return 'Nama produk harus diisi';
                              }
                              if (value.trim().length < 3) {
                                return 'Nama produk minimal 3 karakter';
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
                              labelText: 'Deskripsi Produk *',
                              hintText:
                                  'Deskripsikan produk Anda dengan detail',
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
                                return 'Deskripsi produk harus diisi';
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

                    const SizedBox(height: 16),

                    // Price and Stock Section
                    SectionCard(
                      title: 'Harga & Stok',
                      child: Row(
                        children: [
                          // Price
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Harga (Rp) *',
                                hintText: '0',
                                prefixText: 'Rp ',
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
                                if (value == null || value.isEmpty) {
                                  return 'Harga harus diisi';
                                }
                                final price = double.tryParse(value);
                                if (price == null || price <= 0) {
                                  return 'Harga harus lebih dari 0';
                                }
                                return null;
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Stock
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Stok *',
                                hintText: '0',
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
                                if (value == null || value.isEmpty) {
                                  return 'Stok harus diisi';
                                }
                                final stock = int.tryParse(value);
                                if (stock == null || stock < 0) {
                                  return 'Stok tidak valid';
                                }
                                return null;
                              },
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
                        onPressed: _saveProduct,
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
                          'Simpan Produk',
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
