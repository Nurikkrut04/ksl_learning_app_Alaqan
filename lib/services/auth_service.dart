import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/constants/admin_constants.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _firestore.collection('users').doc(credential.user!.uid).update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isOnline': true,
        });
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<User?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        final googleProvider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');

        final userCredential = await _auth.signInWithPopup(googleProvider);
        final user = userCredential.user;
        await _upsertGoogleUser(user);
        return user;
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      await _upsertGoogleUser(user);
      return user;
    } catch (e) {
      throw 'Google sign-in failed: $e';
    }
  }

  Future<void> _upsertGoogleUser(User? user) async {
    if (user == null) return;

    final role = AdminConstants.isAllowedAdminEmail(user.email)
        ? 'admin'
        : 'user';

    final userRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    if (!userDoc.exists) {
      await userRef.set({
        'email': user.email,
        'displayName': user.displayName ?? '',
        'avatarUrl': user.photoURL ?? '',
        'role': role,
        'hasProfessionsAccess': false,
        'preferredLanguage': 'kk',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
        'isOnline': true,
        'notificationPermissionStatus': 'unknown',
        'authProvider': 'google',
        'settings': {
          'notificationsEnabled': true,
          'offlineMode': true,
          'theme': 'light',
        },
      });
      return;
    }

    await userRef.update({
      'email': user.email,
      'displayName': user.displayName ?? '',
      'avatarUrl': user.photoURL ?? '',
      'role': role,
      'lastLoginAt': FieldValue.serverTimestamp(),
      'isOnline': true,
    });
  }

  Future<User?> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    String preferredLanguage = 'kk',
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.updateDisplayName(displayName);

        await _firestore.collection('users').doc(credential.user!.uid).set({
          'email': email,
          'displayName': displayName,
          'role': 'user',
          'hasProfessionsAccess': false,
          'preferredLanguage': preferredLanguage,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isOnline': true,
          'notificationPermissionStatus': 'unknown',
          'authProvider': 'email',
          'settings': {
            'notificationsEnabled': true,
            'offlineMode': true,
            'theme': 'light',
          },
        });
      }

      return credential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    try {
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).update({
          'isOnline': false,
        });
      }

      if (!kIsWeb) {
        await _googleSignIn.signOut();
      }

      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      await currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      if (currentUser != null) {
        await _firestore.collection('users').doc(currentUser!.uid).delete();
        await currentUser!.delete();
      }
    } catch (e) {
      throw Exception('Account deletion failed: $e');
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email already in use';
      case 'invalid-email':
        return 'Invalid email address';
      case 'weak-password':
        return 'Password is too weak';
      case 'operation-not-allowed':
        return 'Operation not allowed';
      case 'user-disabled':
        return 'User account has been disabled';
      case 'too-many-requests':
        return 'Too many requests. Try again later';
      case 'network-request-failed':
        return 'Network error. Check your connection';
      default:
        return 'Authentication error: ${e.message}';
    }
  }
}
