import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/screens/auth/register_screen.dart';
import 'package:smart/utils/snackbar_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_widgets.dart';

class RegisterScreenSeller extends StatefulWidget {
  const RegisterScreenSeller({Key? key}) : super(key: key);

  @override
  State<RegisterScreenSeller> createState() => _RegisterScreenSellerState();
}

class _RegisterScreenSellerState extends State<RegisterScreenSeller> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _namaTokoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _namaTokoController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
      print('🟡 Tombol Register Seller ditekan');

      final success = await authProvider.registerSeller(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
        _namaTokoController.text,
      );

      if (success && mounted) {
        SnackbarHelper.showSuccessSnackbar(
          context,
          'Registrasi berhasil! Selamat datang sebagai Penjual!',
        );
        Navigator.pop(context);
      } else if (mounted && authProvider.errorMessage != null) {
        SnackbarHelper.showErrorSnackbar(context, authProvider.errorMessage!);
      }
    }
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
          'Daftar sebagai Penjual',
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
                      'Buat Akun Penjual Baru',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Bergabunglah dengan SmartKuliner untuk menjual produk kuliner Anda',
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

                    // Name Field
                    CustomTextField(
                      label: 'Nama Lengkap',
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

                    // Nama Toko Field
                    CustomTextField(
                      label: 'Nama Toko',
                      hint: 'Masukkan nama toko Anda',
                      controller: _namaTokoController,
                      prefixIcon: Icons.store_outlined,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nama toko tidak boleh kosong';
                        }
                        if (value.length < 2) {
                          return 'Nama toko minimal 2 karakter';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Email Field
                    CustomTextField(
                      label: 'Email',
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

                    // Password Field
                    CustomTextField(
                      label: 'Password',
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
                      label: 'Konfirmasi Password',
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
                      text: 'Daftar sebagai Penjual',
                      onPressed: _handleRegister,
                      isLoading: authProvider.isLoading,
                    ),

                    const SizedBox(height: 24),

                    // User Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Ingin daftar sebagai User? ',
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
                                builder: (context) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Daftar Sekarang',
                            style: TextStyle(
                              color: Color(0xFFFF6B35),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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
}
