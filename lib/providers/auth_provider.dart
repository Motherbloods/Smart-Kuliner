import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class MyAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = true; // Start with true untuk initial load
  bool _isInitialized = false; // Track if auth state is initialized
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null && _isInitialized;

  // Add this getter for deeplink service
  Stream<User?> get authStateChanges => _authService.authStateChanges;

  // Initialize auth state
  void initialize() {
    print('🔄 AuthProvider: Initializing auth state...');

    _authService.authStateChanges.listen((User? user) async {
      print('🔄 Auth state changed - User: ${user?.uid}');
      _setLoading(true);

      try {
        if (user != null) {
          print('🔄 Loading user data for: ${user.uid}');
          _currentUser = await _authService.getUserData(user.uid);
          print('✅ User data loaded: ${_currentUser?.name}');
        } else {
          print('🔄 User logged out');
          _currentUser = null;
        }
      } catch (e) {
        print('❌ Error loading user data: $e');
        _currentUser = null;
        _setError(e.toString());
      } finally {
        _isInitialized = true;
        _setLoading(false);
        print(
          '✅ Auth state initialization complete. Authenticated: ${isAuthenticated}',
        );
      }
    });
  }

  // Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
      print('🔄 Loading state changed to: $loading');
    }
  }

  // Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Sign in with email or phone number
  Future<bool> signIn(String emailOrPhone, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      UserCredential? userCredential = await _authService
          .signInWithEmailOrPhone(emailOrPhone, password);
      if (userCredential != null && userCredential.user != null) {
        _currentUser = await _authService.getUserData(userCredential.user!.uid);
      } else {
        _currentUser = null;
      }

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register User Biasa
  Future<bool> registerUser(
    String email,
    String password,
    String name, {
    required String phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? city,
    String? province,
    String? postalCode,
    List<String>? favoriteCategories,
  }) async {
    try {
      clearError();
      _setLoading(true);

      print('🟡 Mulai registrasi user dengan data lengkap');
      print('📧 Email: $email');
      print('👤 Nama: $name');
      print('📱 Phone: $phoneNumber');
      print('🎂 DOB: $dateOfBirth');
      print('⚤ Gender: $gender');
      print('🏠 Address: $address');
      print('🏙️ City: $city');
      print('🗺️ Province: $province');
      print('📮 Postal: $postalCode');
      print('💝 Categories: $favoriteCategories');

      final result = await _authService.registerWithEmailAndPassword(
        email,
        password,
        name,
        phoneNumber: phoneNumber,
        dateOfBirth: dateOfBirth,
        gender: gender,
        address: address,
        city: city,
        province: province,
        postalCode: postalCode,
        favoriteCategories: favoriteCategories,
      );

      if (result != null) {
        print('✅ Registrasi user berhasil');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Registrasi user gagal: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Register Seller
  Future<bool> registerSeller(
    String email,
    String password,
    String name,
    String namaToko, {
    required String phoneNumber,
    Map<String, dynamic>? sellerData,
  }) async {
    _setLoading(true);
    _setError(null);
    print('🟢 MyAuthProvider: registerSeller() terpanggil');

    try {
      UserCredential? userCredential = await _authService
          .registerWithEmailAndPasswordSeller(
            email,
            password,
            name,
            namaToko,
            sellerData,
            phoneNumber: phoneNumber,
          );

      if (userCredential != null && userCredential.user != null) {
        final uid = userCredential.user!.uid;
        _currentUser = await _authService.getUserData(uid);
        print('✅ Registrasi seller berhasil');
        return true;
      } else {
        _currentUser = null;
        return false;
      }
    } catch (e) {
      print('❌ Error saat registrasi seller: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void updateUserData(UserModel updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }

  // Sign out
  Future<void> signOut() async {
    try {
      print('[DEBUG] signOut() called');
      _setLoading(true);
      print('[DEBUG] Loading set to true');

      await _authService.signOut();
      print('[DEBUG] AuthService.signOut() completed');

      _currentUser = null;
      _isInitialized = false; // Reset initialization state
      print('[DEBUG] Current user set to null');
    } catch (e, stackTrace) {
      print('[ERROR] signOut() failed: $e');
      print('[STACKTRACE] $stackTrace');
      _setError(e.toString());
    } finally {
      _setLoading(false);
      print('[DEBUG] Loading set to false');
    }
  }
}
