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

  // Regular user fields
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();

  bool _isLoading = false;
  bool _hasChanges = false;
  SellerModel? _sellerData;
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;

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

  // Gender options for regular users
  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];

  // Tags management for sellers
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

    // Initialize regular user fields
    _phoneController.text = widget.userData.phoneNumber ?? '';
    _addressController.text = widget.userData.address ?? '';
    _cityController.text = widget.userData.city ?? '';
    _provinceController.text = widget.userData.province ?? '';
    _postalCodeController.text = widget.userData.postalCode ?? '';
    _selectedGender = widget.userData.gender;
    _selectedDateOfBirth = widget.userData.dateOfBirth;

    // Initialize seller fields if user is a seller
    if (widget.userData.seller && widget.userData.namaToko != null) {
      _namaTokoController.text = widget.userData.namaToko!;
    }

    // Add listeners to detect changes
    _nameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
    _addressController.addListener(_onFieldChanged);
    _cityController.addListener(_onFieldChanged);
    _provinceController.addListener(_onFieldChanged);
    _postalCodeController.addListener(_onFieldChanged);

    if (widget.userData.seller) {
      _namaTokoController.addListener(_onFieldChanged);
      _descriptionController.addListener(_onFieldChanged);
      _locationController.addListener(_onFieldChanged);
      _categoryController.addListener(_onFieldChanged);
    }
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
    // Check basic user fields
    final nameChanged = _nameController.text.trim() != widget.userData.name;
    final phoneChanged =
        _phoneController.text.trim() != (widget.userData.phoneNumber ?? '');
    final addressChanged =
        _addressController.text.trim() != (widget.userData.address ?? '');
    final cityChanged =
        _cityController.text.trim() != (widget.userData.city ?? '');
    final provinceChanged =
        _provinceController.text.trim() != (widget.userData.province ?? '');
    final postalCodeChanged =
        _postalCodeController.text.trim() != (widget.userData.postalCode ?? '');
    final genderChanged = _selectedGender != widget.userData.gender;
    final dateOfBirthChanged =
        _selectedDateOfBirth != widget.userData.dateOfBirth;

    // Check seller fields if user is a seller
    bool tokoChanged = false;
    bool sellerFieldsChanged = false;

    if (widget.userData.seller) {
      tokoChanged =
          _namaTokoController.text.trim() != (widget.userData.namaToko ?? '');

      if (_sellerData != null) {
        sellerFieldsChanged =
            _descriptionController.text.trim() != _sellerData!.description ||
            _locationController.text.trim() != _sellerData!.location ||
            _categoryController.text.trim() != _sellerData!.category ||
            !_listsEqual(_selectedTags, _sellerData!.tags);
      }
    }

    final hasChanges =
        nameChanged ||
        phoneChanged ||
        addressChanged ||
        cityChanged ||
        provinceChanged ||
        postalCodeChanged ||
        genderChanged ||
        dateOfBirthChanged ||
        tokoChanged ||
        sellerFieldsChanged;

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
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();

    if (widget.userData.seller) {
      _namaTokoController.dispose();
      _descriptionController.dispose();
      _locationController.dispose();
      _categoryController.dispose();
    }
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateOfBirth ??
          DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4DA8DA),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2D3748),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
        _onFieldChanged();
      });
    }
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

      // Regular user fields
      final newPhone = _phoneController.text.trim();
      if (newPhone != (widget.userData.phoneNumber ?? '')) {
        userUpdateData['phoneNumber'] = newPhone.isEmpty ? null : newPhone;
      }

      final newAddress = _addressController.text.trim();
      if (newAddress != (widget.userData.address ?? '')) {
        userUpdateData['address'] = newAddress.isEmpty ? null : newAddress;
      }

      final newCity = _cityController.text.trim();
      if (newCity != (widget.userData.city ?? '')) {
        userUpdateData['city'] = newCity.isEmpty ? null : newCity;
      }

      final newProvince = _provinceController.text.trim();
      if (newProvince != (widget.userData.province ?? '')) {
        userUpdateData['province'] = newProvince.isEmpty ? null : newProvince;
      }

      final newPostalCode = _postalCodeController.text.trim();
      if (newPostalCode != (widget.userData.postalCode ?? '')) {
        userUpdateData['postalCode'] = newPostalCode.isEmpty
            ? null
            : newPostalCode;
      }

      if (_selectedGender != widget.userData.gender) {
        userUpdateData['gender'] = _selectedGender;
      }

      if (_selectedDateOfBirth != widget.userData.dateOfBirth) {
        userUpdateData['dateOfBirth'] = _selectedDateOfBirth?.toIso8601String();
      }

      // Seller specific fields
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
      final updatedUser = widget.userData.copyWith(
        name: userUpdateData.containsKey('name') ? newName : null,
        phoneNumber: userUpdateData.containsKey('phoneNumber')
            ? userUpdateData['phoneNumber']
            : null,
        address: userUpdateData.containsKey('address')
            ? userUpdateData['address']
            : null,
        city: userUpdateData.containsKey('city')
            ? userUpdateData['city']
            : null,
        province: userUpdateData.containsKey('province')
            ? userUpdateData['province']
            : null,
        postalCode: userUpdateData.containsKey('postalCode')
            ? userUpdateData['postalCode']
            : null,
        gender: userUpdateData.containsKey('gender')
            ? userUpdateData['gender']
            : null,
        dateOfBirth: userUpdateData.containsKey('dateOfBirth')
            ? _selectedDateOfBirth
            : null,
        namaToko:
            widget.userData.seller && userUpdateData.containsKey('namaToko')
            ? userUpdateData['namaToko']
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

  Widget _buildRegularUserSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informasi Personal',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),

        // Phone Number
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            label: const Text('Nomor Telepon'),
            prefixIcon: const Icon(
              Icons.phone_outlined,
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
        ),
        const SizedBox(height: 16),

        // Gender Dropdown
        DropdownButtonFormField<String>(
          value: _selectedGender,
          decoration: InputDecoration(
            label: const Text('Jenis Kelamin'),
            prefixIcon: const Icon(
              Icons.person_outline,
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
          items: _genderOptions.map((String gender) {
            return DropdownMenuItem<String>(value: gender, child: Text(gender));
          }).toList(),
          onChanged: (String? newValue) {
            setState(() {
              _selectedGender = newValue;
              _onFieldChanged();
            });
          },
        ),
        const SizedBox(height: 16),

        // Date of Birth
        GestureDetector(
          onTap: _selectDateOfBirth,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  color: Color(0xFF718096),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDateOfBirth != null
                        ? '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}'
                        : 'Tanggal Lahir',
                    style: TextStyle(
                      color: _selectedDateOfBirth != null
                          ? const Color(0xFF2D3748)
                          : const Color(0xFF718096),
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Address Section
        const Text(
          'Alamat',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        const SizedBox(height: 16),

        // Address
        TextFormField(
          controller: _addressController,
          maxLines: 3,
          decoration: InputDecoration(
            label: const Text('Alamat Lengkap'),
            prefixIcon: const Icon(
              Icons.home_outlined,
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
        ),
        const SizedBox(height: 16),

        // City
        TextFormField(
          controller: _cityController,
          decoration: InputDecoration(
            label: const Text('Kota'),
            prefixIcon: const Icon(
              Icons.location_city_outlined,
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
        ),
        const SizedBox(height: 16),

        // Province
        TextFormField(
          controller: _provinceController,
          decoration: InputDecoration(
            label: const Text('Provinsi'),
            prefixIcon: const Icon(
              Icons.map_outlined,
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
        ),
        const SizedBox(height: 16),

        // Postal Code
        TextFormField(
          controller: _postalCodeController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            label: const Text('Kode Pos'),
            prefixIcon: const Icon(
              Icons.markunread_mailbox_outlined,
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
        ),
      ],
    );
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

                // Basic Information (Name)
                BasicInfoSection(
                  userData: widget.userData,
                  nameController: _nameController,
                  namaTokoController: _namaTokoController,
                ),

                const SizedBox(height: 24),

                // Different sections based on user type
                if (widget.userData.seller) ...[
                  // Seller Information
                  SellerInfoSection(
                    descriptionController: _descriptionController,
                    locationController: _locationController,
                    categoryDropdown: _buildCategoryDropdown(),
                  ),

                  const SizedBox(height: 24),

                  // Tags Selector
                  _buildTagSelector(),
                ] else ...[
                  // Regular User Information
                  _buildRegularUserSection(),
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
