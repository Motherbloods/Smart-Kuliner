import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/utils/snackbar_helper.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Clear any previous errors when entering login screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MyAuthProvider>(context, listen: false).clearError();
    });
  }

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _isEmail(String input) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input.trim());
  }

  bool _isPhoneNumber(String input) {
    String cleaned = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return RegExp(r'^(\+?62|0)8[0-9]{8,11}$').hasMatch(cleaned);
  }

  String? _validateEmailOrPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email atau nomor telepon tidak boleh kosong';
    }

    String cleanValue = value.trim();

    if (cleanValue.contains('@')) {
      if (!_isEmail(cleanValue)) {
        return 'Format email tidak valid';
      }
    } else {
      if (!_isPhoneNumber(cleanValue)) {
        return 'Format nomor telepon tidak valid\nContoh: 08123456789 atau +628123456789';
      }
    }

    return null;
  }

  void _handleLogin() async {
    Provider.of<MyAuthProvider>(context, listen: false).clearError();

    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<MyAuthProvider>(context, listen: false);

      FocusScope.of(context).unfocus();

      final success = await authProvider.signIn(
        _emailOrPhoneController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        SnackbarHelper.showSuccessSnackbar(
          context,
          'Login berhasil!',
          duration: 2,
        );
      } else if (mounted && authProvider.errorMessage != null) {
        SnackbarHelper.showErrorSnackbar(
          context,
          authProvider.errorMessage!,
          duration: 3,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                    const SizedBox(height: 40),

                    // Logo and Title
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF4DA8DA),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.restaurant,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'SmartKuliner',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Temukan kuliner terbaik di sekitar Anda',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF718096),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Welcome Text
                    const Text(
                      'Selamat Datang!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masuk ke akun Anda untuk melanjutkan',
                      style: TextStyle(fontSize: 16, color: Color(0xFF718096)),
                    ),

                    const SizedBox(height: 32),

                    // Error Message
                    if (authProvider.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red.shade700,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authProvider.errorMessage!,
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => authProvider.clearError(),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.red.shade700,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    CustomTextField(
                      label: 'Email atau Nomor Telepon',
                      hint: 'Masukkan email atau nomor telepon',
                      controller: _emailOrPhoneController,
                      prefixIcon: _emailOrPhoneController.text.contains('@')
                          ? Icons.email_outlined
                          : Icons.phone_outlined,
                      keyboardType: _emailOrPhoneController.text.contains('@')
                          ? TextInputType.emailAddress
                          : TextInputType.text, // atau visiblePassword

                      enabled: !authProvider.isLoading,
                      validator: _validateEmailOrPhone,
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),

                    const SizedBox(height: 16),

                    // Helper text
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'Contoh: user@email.com atau 08123456789',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Password Field
                    CustomTextField(
                      label: 'Password',
                      hint: 'Masukkan password Anda',
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outlined,
                      isPassword: true,
                      enabled: !authProvider.isLoading,
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

                    const SizedBox(height: 32),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4DA8DA),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Masuk',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Register Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Belum punya akun? ',
                          style: TextStyle(
                            color: Color(0xFF718096),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: authProvider.isLoading
                              ? null
                              : () {
                                  authProvider.clearError();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegisterScreen(),
                                    ),
                                  );
                                },
                          child: Text(
                            'Daftar Sekarang',
                            style: TextStyle(
                              color: authProvider.isLoading
                                  ? const Color(0xFF718096)
                                  : const Color(0xFF4DA8DA),
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
