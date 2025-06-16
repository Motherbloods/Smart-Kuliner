import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/screens/auth/register_seller_screen.dart';
import 'package:smart/utils/snackbar_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalCodeController = TextEditingController();

  DateTime? _selectedDateOfBirth;
  String? _selectedGender;
  List<String> _selectedCategories = [];

  final List<String> _genderOptions = ['Laki-laki', 'Perempuan'];
  final List<String> _categoryOptions = [
    'Makanan Tradisional',
    'Makanan Modern',
    'Minuman',
    'Dessert',
    'Healthy Food',
    'Fast Food',
    'Street Food',
    'Organic Food',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _provinceController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
      print('🟡 Tombol Register User ditekan');

      final success = await authProvider.registerUser(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
        phoneNumber: _phoneController.text.isNotEmpty
            ? _phoneController.text
            : null,
        dateOfBirth: _selectedDateOfBirth,
        gender: _selectedGender,
        address: _addressController.text.isNotEmpty
            ? _addressController.text
            : null,
        city: _cityController.text.isNotEmpty ? _cityController.text : null,
        province: _provinceController.text.isNotEmpty
            ? _provinceController.text
            : null,
        postalCode: _postalCodeController.text.isNotEmpty
            ? _postalCodeController.text
            : null,
        favoriteCategories: _selectedCategories,
      );

      if (success && mounted) {
        SnackbarHelper.showSuccessSnackbar(
          context,
          'Registrasi berhasil! Selamat datang sebagai User!',
        );
        Navigator.pop(context);
      } else if (mounted && authProvider.errorMessage != null) {
        SnackbarHelper.showErrorSnackbar(context, authProvider.errorMessage!);
      }
    }
  }

  Future<void> _selectDateOfBirth() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(
        const Duration(days: 6570),
      ), // 18 years ago
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF4DA8DA)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
        title: const Text(
          'Daftar sebagai User',
          style: TextStyle(color: Color(0xFF2D3748)),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Consumer<MyAuthProvider>(
            builder: (context, authProvider, child) {
              return Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    const Text(
                      'Buat Akun User Baru',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bergabunglah dengan SmartKuliner untuk menemukan kuliner terbaik',
                      style: TextStyle(fontSize: 16, color: Color(0xFF718096)),
                    ),

                    const SizedBox(height: 32),

                    // Error Message
                    if (authProvider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ErrorMessage(
                          message: authProvider.errorMessage!,
                        ),
                      ),

                    // Basic Information Section
                    _buildSectionHeader('Informasi Dasar'),
                    const SizedBox(height: 16),

                    // Name Field
                    CustomTextField(
                      label: 'Nama Lengkap *',
                      hint: 'Masukkan nama lengkap Anda',
                      controller: _nameController,
                      prefixIcon: Icons.person_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama tidak boleh kosong';
                        }
                        if (value.length < 2) {
                          return 'Nama minimal 2 karakter';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Email Field
                    CustomTextField(
                      label: 'Email *',
                      hint: 'Masukkan email Anda',
                      controller: _emailController,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email tidak boleh kosong';
                        }
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value)) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Phone Field
                    CustomTextField(
                      label: 'Nomor Telepon',
                      hint: 'Masukkan nomor telepon Anda',
                      controller: _phoneController,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length < 10) {
                            return 'Nomor telepon minimal 10 digit';
                          }
                          if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                            return 'Nomor telepon hanya boleh berisi angka';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Date of Birth Field
                    InkWell(
                      onTap: _selectDateOfBirth,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Tanggal Lahir',
                          hintText: 'Pilih tanggal lahir Anda',
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF4DA8DA),
                            ),
                          ),
                        ),
                        child: Text(
                          _selectedDateOfBirth != null
                              ? _formatDate(_selectedDateOfBirth!)
                              : 'Pilih tanggal lahir',
                          style: TextStyle(
                            color: _selectedDateOfBirth != null
                                ? const Color(0xFF2D3748)
                                : const Color(0xFF718096),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Gender Field
                    DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(
                        labelText: 'Jenis Kelamin',
                        hintText: 'Pilih jenis kelamin',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF4DA8DA),
                          ),
                        ),
                      ),
                      items: _genderOptions.map((String gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                    ),

                    const SizedBox(height: 32),

                    // Address Information Section
                    _buildSectionHeader('Informasi Alamat'),
                    const SizedBox(height: 16),

                    // Address Field
                    CustomTextField(
                      label: 'Alamat Lengkap',
                      hint: 'Masukkan alamat lengkap Anda',
                      controller: _addressController,
                      prefixIcon: Icons.location_on_outlined,
                    ),

                    const SizedBox(height: 20),

                    // City and Province Row
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'Kota',
                            hint: 'Masukkan kota',
                            controller: _cityController,
                            prefixIcon: Icons.location_city_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            label: 'Provinsi',
                            hint: 'Masukkan provinsi',
                            controller: _provinceController,
                            prefixIcon: Icons.map_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Postal Code Field
                    CustomTextField(
                      label: 'Kode Pos',
                      hint: 'Masukkan kode pos',
                      controller: _postalCodeController,
                      prefixIcon: Icons.markunread_mailbox_outlined,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          if (value.length != 5) {
                            return 'Kode pos harus 5 digit';
                          }
                          if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                            return 'Kode pos hanya boleh berisi angka';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Preferences Section
                    _buildSectionHeader('Preferensi Kuliner'),
                    const SizedBox(height: 16),

                    // Category Selection
                    const Text(
                      'Pilih kategori kuliner favorit Anda:',
                      style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categoryOptions.map((category) {
                        final isSelected = _selectedCategories.contains(
                          category,
                        );
                        return FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (bool selected) {
                            setState(() {
                              if (selected) {
                                _selectedCategories.add(category);
                              } else {
                                _selectedCategories.remove(category);
                              }
                            });
                          },
                          backgroundColor: Colors.grey[100],
                          selectedColor: const Color(
                            0xFF4DA8DA,
                          ).withOpacity(0.2),
                          checkmarkColor: const Color(0xFF4DA8DA),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFF4DA8DA)
                                : const Color(0xFF718096),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    // Security Section
                    _buildSectionHeader('Keamanan Akun'),
                    const SizedBox(height: 16),

                    // Password Field
                    CustomTextField(
                      label: 'Password *',
                      hint: 'Masukkan password Anda',
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outlined,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password tidak boleh kosong';
                        }
                        if (value.length < 6) {
                          return 'Password minimal 6 karakter';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Confirm Password Field
                    CustomTextField(
                      label: 'Konfirmasi Password *',
                      hint: 'Masukkan ulang password Anda',
                      controller: _confirmPasswordController,
                      prefixIcon: Icons.lock_outlined,
                      isPassword: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Konfirmasi password tidak boleh kosong';
                        }
                        if (value != _passwordController.text) {
                          return 'Password tidak sama';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 32),

                    // Register Button
                    CustomButton(
                      text: 'Daftar sebagai User',
                      onPressed: _handleRegister,
                      isLoading: authProvider.isLoading,
                    ),

                    const SizedBox(height: 24),

                    // Seller Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Ingin daftar sebagai Penjual? ',
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const RegisterScreenSeller(),
                              ),
                            );
                          },
                          child: const Text(
                            'Daftar Sekarang',
                            style: TextStyle(
                              color: Color(0xFF4DA8DA),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Required fields note
                    const Text(
                      '* Field yang wajib diisi',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF718096),
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF4DA8DA),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }
}
