import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class MyAuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Initialize auth state
  void initialize() {
    _authService.authStateChanges.listen((User? user) async {
      if (user != null) {
        _currentUser = await _authService.getUserData(user.uid);
      } else {
        _currentUser = null;
      }
      notifyListeners();
    });
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
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

  // Sign in
  Future<bool> signIn(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      UserCredential? userCredential = await _authService
          .signInWithEmailAndPassword(email, password);
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
  Future<bool> registerUser(String email, String password, String name) async {
    try {
      _setLoading(true);
      _setError(null);
      print('🟢 MyAuthProvider: registerUser() terpanggil');

      UserCredential? userCredential = await _authService
          .registerWithEmailAndPassword(email, password, name);

      if (userCredential != null && userCredential.user != null) {
        _currentUser = await _authService.getUserData(userCredential.user!.uid);
        return true;
      } else {
        _currentUser = null;
        return false;
      }
    } catch (e) {
      print('❌ Error registerUser: $e');
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
    String namaToko,
  ) async {
    try {
      _setLoading(true);
      _setError(null);
      print('🟢 MyAuthProvider: registerSeller() terpanggil');

      UserCredential? userCredential = await _authService
          .registerWithEmailAndPasswordSeller(email, password, name, namaToko);

      if (userCredential != null && userCredential.user != null) {
        _currentUser = await _authService.getUserData(userCredential.user!.uid);
        return true;
      } else {
        _currentUser = null;
        return false;
      }
    } catch (e) {
      print('❌ Error registerSeller: $e');
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
