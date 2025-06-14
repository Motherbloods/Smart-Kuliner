// lib/managers/user_manager.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart/models/user.dart';
import 'package:smart/providers/auth_provider.dart';
import 'package:smart/utils/snackbar_helper.dart';

class UserManager {
  // Singleton pattern
  static final UserManager _instance = UserManager._internal();
  factory UserManager() => _instance;
  UserManager._internal();

  /// Get current user data from AuthProvider
  UserModel? getCurrentUser(BuildContext context) {
    try {
      final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
      return authProvider.currentUser;
    } catch (e) {
      print('⚠️ Error getting current user: $e');
      return null;
    }
  }

  /// Load user data with error handling
  Future<UserModel?> loadUserData(BuildContext context) async {
    try {
      final authProvider = Provider.of<MyAuthProvider>(context, listen: false);
      final userData = authProvider.currentUser;

      if (userData != null) {
        print('✅ User data loaded successfully: ${userData.uid}');
      } else {
        print('⚠️ No user data available');
      }

      return userData;
    } catch (e) {
      if (context.mounted) {
        SnackbarHelper.showErrorSnackbar(
          context,
          'Gagal memuat data profil: $e',
        );
      }
      print('❌ Error loading user data: $e');
      return null;
    }
  }

  /// Check if user is authenticated
  bool isUserAuthenticated(BuildContext context) {
    final userData = getCurrentUser(context);
    return userData != null && userData.uid.isNotEmpty;
  }

  /// Get user ID safely
  String? getUserId(BuildContext context) {
    final userData = getCurrentUser(context);
    return userData?.uid;
  }

  /// Get user email safely
  String? getUserEmail(BuildContext context) {
    final userData = getCurrentUser(context);
    return userData?.email;
  }

  /// Get user name safely
  String? getUserName(BuildContext context) {
    final userData = getCurrentUser(context);
    return userData?.name;
  }

  /// Validate user session
  Future<bool> validateUserSession(BuildContext context) async {
    try {
      final authProvider = Provider.of<MyAuthProvider>(context, listen: false);

      // Check if user is still authenticated
      if (authProvider.currentUser == null) {
        return false;
      }

      // Additional validation logic can be added here
      // For example, checking token expiry, etc.

      return true;
    } catch (e) {
      print('⚠️ Error validating user session: $e');
      return false;
    }
  }

  /// Handle user authentication errors
  void handleAuthError(BuildContext context, String error) {
    if (context.mounted) {
      SnackbarHelper.showErrorSnackbar(context, 'Error autentikasi: $error');
    }
  }
}
