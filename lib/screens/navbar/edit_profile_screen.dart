import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/widgets/editprofile/basic_info_section.dart';
import 'package:smart/widgets/editprofile/profile_header.dart';
import 'package:smart/widgets/editprofile/save_button.dart';
import 'package:smart/widgets/editprofile/seller_info_section.dart';
import '../../providers/auth_provider.dart';
import '../../models/user.dart';
import '../../models/seller.dart';
import '../../utils/snackbar_helper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel userData;

  const EditProfileScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _namaTokoController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _categoryController = TextEditingController();

  bool _isLoading = false;
  bool _hasChanges = false;
  SellerModel? _sellerData;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Categories for seller
  final List<String> _categories = [
    'Semua',
    'Makanan Utama',
    'Cemilan',
    'Minuman',
    'Makanan Sehat',
    'Dessert',
    "Lainnya",
  ];

  // Tags management
  List<String> _selectedTags = [];
  final List<String> _availableTags = [
    'Halal',
    'Vegetarian',
    'Vegan',
    'Spicy',
    'Sweet',
    'Healthy',
    'Traditional',
    'Modern',
    'Homemade',
    'Organic',
    'Local',
    'International',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.userData.seller) {
      _loadSellerData();
    }
  }

  void _initializeControllers() {
    _nameController.text = widget.userData.name;
    if (widget.userData.seller && widget.userData.namaToko != null) {
      _namaTokoController.text = widget.userData.namaToko!;
    }

    // Add listeners to detect changes
    _nameController.addListener(_onFieldChanged);
    _namaTokoController.addListener(_onFieldChanged);
    _descriptionController.addListener(_onFieldChanged);
    _locationController.addListener(_onFieldChanged);
    _categoryController.addListener(_onFieldChanged);
  }

  Future<void> _loadSellerData() async {
    try {
      final sellerDoc = await _firestore
          .collection('sellers')
          .doc(widget.userData.uid)
          .get();

      if (sellerDoc.exists) {
        setState(() {
          _sellerData = SellerModel.fromMap(
            sellerDoc.data()!,
            widget.userData.uid,
          );
          _descriptionController.text = _sellerData?.description ?? '';
          _locationController.text = _sellerData?.location ?? '';
          _categoryController.text = _sellerData?.category ?? '';
          _selectedTags = List<String>.from(_sellerData?.tags ?? []);
        });
      }
    } catch (e) {
      print('❌ Error loading seller data: $e');
    }
  }

  void _onFieldChanged() {
    final nameChanged = _nameController.text.trim() != widget.userData.name;
    final tokoChanged =
        widget.userData.seller &&
        _namaTokoController.text.trim() != (widget.userData.namaToko ?? '');

    bool sellerFieldsChanged = false;
    if (widget.userData.seller && _sellerData != null) {
      sellerFieldsChanged =
          _descriptionController.text.trim() != _sellerData!.description ||
          _locationController.text.trim() != _sellerData!.location ||
          _categoryController.text.trim() != _sellerData!.category ||
          !_listsEqual(_selectedTags, _sellerData!.tags);
    }

    final hasChanges = nameChanged || tokoChanged || sellerFieldsChanged;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  bool _listsEqual(List<String> list1, List<String> list2) {
    if (list1.length != list2.length) return false;
    for (int i = 0; i < list1.length; i++) {
      if (!list2.contains(list1[i])) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _namaTokoController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare user data updates
      Map<String, dynamic> userUpdateData = {};

      final newName = _nameController.text.trim();
      if (newName != widget.userData.name) {
        userUpdateData['name'] = newName;
      }

      if (widget.userData.seller) {
        final newNamaToko = _namaTokoController.text.trim();
        if (newNamaToko != (widget.userData.namaToko ?? '')) {
          userUpdateData['namaToko'] = newNamaToko;
        }
      }

      // Update user data if there are changes
      if (userUpdateData.isNotEmpty) {
        await _firestore
            .collection('users')
            .doc(widget.userData.uid)
            .update(userUpdateData);
      }

      // Update seller data if user is a seller
      if (widget.userData.seller) {
        Map<String, dynamic> sellerUpdateData = {};

        final newDescription = _descriptionController.text.trim();
        final newLocation = _locationController.text.trim();
        final newCategory = _categoryController.text.trim();

        if (_sellerData != null) {
          if (newDescription != _sellerData!.description) {
            sellerUpdateData['description'] = newDescription;
          }
          if (newLocation != _sellerData!.location) {
            sellerUpdateData['location'] = newLocation;
          }
          if (newCategory != _sellerData!.category) {
            sellerUpdateData['category'] = newCategory;
          }
          if (!_listsEqual(_selectedTags, _sellerData!.tags)) {
            sellerUpdateData['tags'] = _selectedTags;
          }
        } else {
          // Create new seller document if doesn't exist
          sellerUpdateData = {
            'id': widget.userData.uid,
            'namaToko': _namaTokoController.text.trim(),
            'description': newDescription,
            'location': newLocation,
            'category': newCategory,
            'profileImage': '',
            'rating': 0.0,
            'totalProducts': 0,
            'isVerified': false,
            'joinedDate': DateTime.now().millisecondsSinceEpoch,
            'tags': _selectedTags,
          };
        }

        // Always update namaToko in seller document
        if (userUpdateData.containsKey('namaToko')) {
          sellerUpdateData['namaToko'] = userUpdateData['namaToko'];
        }

        if (sellerUpdateData.isNotEmpty) {
          await _firestore
              .collection('sellers')
              .doc(widget.userData.uid)
              .set(sellerUpdateData, SetOptions(merge: true));
        }
      }

      // Update local user data
      final updatedUser = UserModel(
        uid: widget.userData.uid,
        email: widget.userData.email,
        name: userUpdateData.containsKey('name')
            ? newName
            : widget.userData.name,
        createdAt: widget.userData.createdAt,
        seller: widget.userData.seller,
        namaToko: widget.userData.seller
            ? (userUpdateData.containsKey('namaToko')
                  ? _namaTokoController.text.trim()
                  : widget.userData.namaToko)
            : null,
      );

      // Update in auth provider
      if (mounted) {
        final authProvider = Provider.of<MyAuthProvider>(
          context,
          listen: false,
        );
        authProvider.updateUserData(updatedUser);
      }

      if (mounted) {
        SnackbarHelper.showSuccessSnackbar(
          context,
          'Profile berhasil diperbarui!',
        );
        Navigator.pop(context, updatedUser);
      }
    } catch (e) {
      print('❌ Error updating profile: $e');
      if (mounted) {
        SnackbarHelper.showErrorSnackbar(
          context,
          'Gagal memperbarui profile: ${e.toString()}',
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

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Perubahan Belum Disimpan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        content: const Text(
          'Anda memiliki perubahan yang belum disimpan. Apakah Anda yakin ingin keluar?',
          style: TextStyle(color: Color(0xFF4A5568)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Batal',
              style: TextStyle(color: Color(0xFF718096)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  Widget _buildTagSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tags Toko',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pilih tag yang sesuai dengan toko Anda (maksimal 5 tag)',
          style: TextStyle(fontSize: 12, color: Color(0xFF718096)),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(
                      tag,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF2D3748),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected && _selectedTags.length < 5) {
                          _selectedTags.add(tag);
                          _onFieldChanged();
                        } else if (!selected) {
                          _selectedTags.remove(tag);
                          _onFieldChanged();
                        }
                      });
                    },
                    selectedColor: const Color(0xFF4DA8DA),
                    backgroundColor: Colors.white,
                    checkmarkColor: Colors.white,
                    elevation: isSelected ? 2 : 0,
                    shadowColor: const Color(0xFF4DA8DA).withOpacity(0.3),
                  );
                }).toList(),
              ),
              if (_selectedTags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4DA8DA).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Tag terpilih: ${_selectedTags.length}/5',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4DA8DA),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
            onPressed: () async {
              if (await _onWillPop()) {
                Navigator.pop(context);
              }
            },
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              color: Color(0xFF2D3748),
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _updateProfile,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF4DA8DA),
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
              children: [
                const SizedBox(height: 8),

                // Profile Avatar Section
                ProfileHeader(userData: widget.userData),

                const SizedBox(height: 24),

                // Basic Information
                BasicInfoSection(
                  userData: widget.userData,
                  nameController: _nameController,
                  namaTokoController: _namaTokoController,
                ),

                // Seller Information (only for sellers)
                if (widget.userData.seller) ...[
                  const SizedBox(height: 24),
                  SellerInfoSection(
                    descriptionController: _descriptionController,
                    locationController: _locationController,
                    categoryDropdown: _buildCategoryDropdown(),
                  ),

                  const SizedBox(height: 24),

                  // Tags Selector
                  _buildTagSelector(),
                ],

                const SizedBox(height: 32),

                // Save Button
                SaveButton(
                  hasChanges: _hasChanges,
                  isLoading: _isLoading,
                  onPressed: _updateProfile,
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori Toko',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _categoryController.text.isEmpty
              ? null
              : _categoryController.text,
          decoration: InputDecoration(
            prefixIcon: const Icon(
              Icons.category_outlined,
              color: Color(0xFF718096),
            ),
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
              borderSide: const BorderSide(color: Color(0xFF4DA8DA), width: 2),
            ),
            filled: true,
            fillColor: const Color(0xFFF7FAFC),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          items: _categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _categoryController.text = newValue ?? '';
              _onFieldChanged();
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Pilih kategori toko';
            }
            return null;
          },
        ),
      ],
    );
  }
}
