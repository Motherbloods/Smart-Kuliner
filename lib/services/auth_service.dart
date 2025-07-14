import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart/models/seller.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email or phone number
  Future<UserCredential?> signInWithEmailOrPhone(
    String emailOrPhone,
    String password,
  ) async {
    try {
      String email = emailOrPhone.trim();

      // Check if input is phone number (starts with numbers)
      if (RegExp(r'^[0-9+]').hasMatch(emailOrPhone)) {
        // It's a phone number, find the email associated with it
        email = await _getEmailFromPhoneNumber(emailOrPhone.trim());
      }

      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update last login time
      if (result.user != null) {
        await _updateLastLoginTime(result.user!.uid);
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw e.toString();
    }
  }

  // Get email from phone number
  Future<String> _getEmailFromPhoneNumber(String phoneNumber) async {
    try {
      // Clean phone number (remove spaces, dashes, etc.)
      String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

      // If doesn't start with +, assume it's Indonesian number
      if (!cleanPhone.startsWith('+')) {
        if (cleanPhone.startsWith('0')) {
          cleanPhone = '+62${cleanPhone.substring(1)}';
        } else if (cleanPhone.startsWith('62')) {
          cleanPhone = '+$cleanPhone';
        } else {
          cleanPhone = '+62$cleanPhone';
        }
      }

      // Query Firestore to find user with this phone number
      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: cleanPhone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        // Also try with original phone number format
        querySnapshot = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: phoneNumber)
            .limit(1)
            .get();
      }

      if (querySnapshot.docs.isEmpty) {
        throw 'Nomor telepon tidak ditemukan';
      }

      final userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
      return userData['email'] as String;
    } catch (e) {
      throw 'Nomor telepon tidak ditemukan';
    }
  }

  // Register with email and password (User Biasa)
  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
    String name, {
    required String phoneNumber, // Now required
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? city,
    String? province,
    String? postalCode,
    List<String>? favoriteCategories,
  }) async {
    try {
      // Validate phone number is provided
      if (phoneNumber.isEmpty) {
        throw 'Nomor telepon wajib diisi';
      }

      // Check if phone number already exists
      await _checkPhoneNumberExists(phoneNumber);

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null) {
        try {
          await _createUserDocument(
            result.user!,
            name,
            false,
            null,
            null,
            phoneNumber: phoneNumber,
            dateOfBirth: dateOfBirth,
            gender: gender,
            address: address,
            city: city,
            province: province,
            postalCode: postalCode,
            favoriteCategories: favoriteCategories,
          );
        } catch (firestoreError) {
          print('❌ Firestore error saat buat user document: $firestoreError');
          // Hapus user dari Firebase Auth jika gagal buat document
          await result.user!.delete();
          throw firestoreError;
        }
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e, stacktrace) {
      print('❌ Error tidak terduga: $e');
      print('Stacktrace: $stacktrace');
      throw e;
    }
  }

  // Register with email and password (Seller)
  Future<UserCredential?> registerWithEmailAndPasswordSeller(
    String email,
    String password,
    String name,
    String namaToko,
    Map<String, dynamic>? sellerData, {
    required String phoneNumber, // Now required
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? city,
    String? province,
    String? postalCode,
  }) async {
    try {
      // Validate phone number is provided
      if (phoneNumber.isEmpty) {
        throw 'Nomor telepon wajib diisi';
      }

      // Check if phone number already exists
      await _checkPhoneNumberExists(phoneNumber);

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null) {
        try {
          await _createUserDocument(
            result.user!,
            name,
            true,
            namaToko,
            sellerData,
            phoneNumber: phoneNumber,
            dateOfBirth: dateOfBirth,
            gender: gender,
            address: address,
            city: city,
            province: province,
            postalCode: postalCode,
          );
        } catch (firestoreError) {
          print('❌ Firestore error saat buat seller document: $firestoreError');
          // Hapus user dari Firebase Auth jika gagal buat document
          await result.user!.delete();
          throw firestoreError;
        }
      }

      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e, stacktrace) {
      print('❌ Error tidak terduga: $e');
      print('Stacktrace: $stacktrace');
      throw e;
    }
  }

  // Check if phone number already exists
  Future<void> _checkPhoneNumberExists(String phoneNumber) async {
    try {
      String cleanPhone = _cleanPhoneNumber(phoneNumber);

      QuerySnapshot querySnapshot = await _firestore
          .collection('users')
          .where('phoneNumber', isEqualTo: cleanPhone)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        throw 'Nomor telepon sudah digunakan';
      }
    } catch (e) {
      if (e.toString().contains('sudah digunakan')) {
        throw e;
      }
      // Other errors, continue with registration
    }
  }

  // Clean phone number format
  String _cleanPhoneNumber(String phoneNumber) {
    String cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    // Normalize Indonesian phone numbers
    if (!cleanPhone.startsWith('+')) {
      if (cleanPhone.startsWith('0')) {
        cleanPhone = '+62${cleanPhone.substring(1)}';
      } else if (cleanPhone.startsWith('62')) {
        cleanPhone = '+$cleanPhone';
      } else {
        cleanPhone = '+62$cleanPhone';
      }
    }

    return cleanPhone;
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(
    User user,
    String name,
    bool isSeller,
    String? namaToko,
    Map<String, dynamic>? sellerData, {
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    String? address,
    String? city,
    String? province,
    String? postalCode,
    List<String>? favoriteCategories,
  }) async {
    try {
      final userModel = UserModel(
        uid: user.uid,
        email: user.email!,
        name: name,
        createdAt: DateTime.now(),
        seller: isSeller,
        namaToko: isSeller ? namaToko : null,
        phoneNumber: phoneNumber != null
            ? _cleanPhoneNumber(phoneNumber)
            : null,
        dateOfBirth: dateOfBirth,
        gender: gender,
        address: address,
        city: city,
        province: province,
        postalCode: postalCode,
        favoriteCategories: favoriteCategories ?? [],
        emailVerified: user.emailVerified,
        phoneVerified: false,
        lastLoginAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());

      print('✅ User berhasil disimpan di koleksi "users"');

      if (isSeller && sellerData != null) {
        print('ini sellerss');
        final sellerModel = SellerModel(
          id: user.uid,
          nameToko: sellerData['nameToko'] ?? '',
          description: sellerData['description'] ?? '',
          profileImage: '',
          location: sellerData['location'] ?? '',
          rating: 0.0,
          totalProducts: 0,
          isVerified: true,
          joinedDate: DateTime.now(),
          category: sellerData['category'] ?? 'Lainnya',
          tags: List<String>.from(sellerData['tags'] ?? []),
        );

        await _firestore
            .collection('sellers')
            .doc(user.uid)
            .set(sellerModel.toMap());

        print('✅ Seller berhasil disimpan di koleksi "sellers"');
      }
    } catch (e) {
      print('❌ Gagal menyimpan data user/seller: $e');
      throw e;
    }
  }

  // Update last login time
  Future<void> _updateLastLoginTime(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'lastLoginAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('❌ Gagal update last login time: $e');
      // Don't throw error, just log it
    }
  }

  // Get user data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        print('🔍 Data ditemukan untuk UID: $uid');
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, uid);
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(
    String uid,
    Map<String, dynamic> updates,
  ) async {
    try {
      // If updating phone number, clean it first
      if (updates.containsKey('phoneNumber')) {
        updates['phoneNumber'] = _cleanPhoneNumber(updates['phoneNumber']);
      }

      await _firestore.collection('users').doc(uid).update(updates);
      print('✅ Profile berhasil diupdate');
      return true;
    } catch (e) {
      print('❌ Gagal update profile: $e');
      return false;
    }
  }

  // Verify email
  Future<void> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      throw 'Gagal mengirim email verifikasi';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Gagal mengirim email reset password';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Gagal keluar dari akun';
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'Email tidak ditemukan';
      case 'wrong-password':
        return 'Password salah';
      case 'email-already-in-use':
        return 'Email sudah digunakan';
      case 'weak-password':
        return 'Password terlalu lemah';
      case 'invalid-email':
        return 'Format email tidak valid';
      case 'user-disabled':
        return 'Akun telah dinonaktifkan';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi nanti';
      default:
        return 'Terjadi kesalahan: ${e.message}';
    }
  }
}
