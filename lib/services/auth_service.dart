import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return result;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Terjadi kesalahan yang tidak terduga';
    }
  }

  // Register with email and password (User Biasa)
  Future<UserCredential?> registerWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null) {
        try {
          await _createUserDocument(result.user!, name, false, null);
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
  ) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      if (result.user != null) {
        try {
          await _createUserDocument(result.user!, name, true, namaToko);
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

  // Create user document in Firestore
  Future<void> _createUserDocument(
    User user,
    String name,
    bool isSeller,
    String? namaToko,
  ) async {
    try {
      print(
        '✅ Menyimpan ${isSeller ? 'seller' : 'user'} ke Firestore dengan UID: ${user.uid}',
      );

      UserModel userModel = UserModel(
        uid: user.uid,
        email: user.email!,
        name: name,
        createdAt: DateTime.now(),
        seller: isSeller,
        namaToko: isSeller ? namaToko : null,
      );

      await _firestore.collection('users').doc(user.uid).set(userModel.toMap());
      print('✅ ${isSeller ? 'Seller' : 'User'} berhasil disimpan di Firestore');
    } catch (e) {
      print(
        '❌ Gagal menyimpan ${isSeller ? 'seller' : 'user'} ke Firestore: $e',
      );
      throw e;
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
