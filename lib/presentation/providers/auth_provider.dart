import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/constants/admin_constants.dart';
import '../../data/models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/notification_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService.instance;

  User? _firebaseUser;
  UserModel? _userModel;
  bool _isLoading = false;
  String? _errorMessage;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isAdmin => _userModel?.isAdmin ?? false;
  bool get hasProfessionsAccess => _userModel?.hasProfessionsAccess ?? false;
  bool get notificationsEnabled =>
      _userModel?.settings.notificationsEnabled ?? true;
  String get notificationPermissionStatus =>
      _userModel?.notificationPermissionStatus ?? 'unknown';
  bool get hasAdminAccess =>
      AdminConstants.isAllowedAdminEmail(_firebaseUser?.email) && isAdmin;

  AuthProvider() {
    _initAuth();
  }

  void _initAuth() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      _firebaseUser = user;

      if (user != null) {
        await _loadUserData(user.uid);
        if (_userModel != null) {
          await _notificationService.syncUserState(_userModel!);
          await _loadUserData(user.uid);
        }
      } else {
        _userModel = null;
      }

      notifyListeners();
    });
  }

  Future<void> _loadUserData(String uid) async {
    try {
      _userModel = await _firestoreService.getUser(uid);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _authService.signInWithEmail(email, password);

      if (user != null) {
        await _loadUserData(user.uid);
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Sign in failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Sign in with Google
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _authService.signInWithGoogle();

      if (user != null) {
        await _loadUserData(user.uid);
        _setLoading(false);
        return true;
      } else {
        // User cancelled Google sign-in
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Register new user
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
    String? preferredLanguage,
  }) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      final user = await _authService.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
        preferredLanguage: preferredLanguage ?? 'kk',
      );

      if (user != null) {
        await _loadUserData(user.uid);
        _setLoading(false);
        return true;
      } else {
        _errorMessage = 'Registration failed';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    _setLoading(true);

    try {
      if (_firebaseUser != null) {
        await _notificationService.detachCurrentUser();
      }
      await _authService.signOut();
      _userModel = null;
      _firebaseUser = null;
      _setLoading(false);
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await _authService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? preferredLanguage,
  }) async {
    if (_userModel == null) return false;

    _setLoading(true);

    try {
      final updatedUser = _userModel!.copyWith(
        displayName: displayName ?? _userModel!.displayName,
        avatarUrl: avatarUrl ?? _userModel!.avatarUrl,
        preferredLanguage: preferredLanguage ?? _userModel!.preferredLanguage,
      );

      await _firestoreService.updateUser(updatedUser);
      _userModel = updatedUser;
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  Future<bool> purchaseProfessionsAccess() async {
    final uid = _firebaseUser?.uid;
    if (uid == null) {
      _errorMessage = 'User is not authenticated';
      notifyListeners();
      return false;
    }

    if (hasProfessionsAccess) {
      return true;
    }

    _setLoading(true);
    _errorMessage = null;

    try {
      await _firestoreService.activateProfessionsAccess(uid);
      await _loadUserData(uid);
      if (_userModel != null) {
        await _notificationService.syncUserState(_userModel!);
        await _loadUserData(uid);
      }
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<bool> updateNotificationsEnabled(bool enabled) async {
    final uid = _firebaseUser?.uid;
    if (_userModel == null || uid == null) return false;

    _setLoading(true);
    _errorMessage = null;

    try {
      await _firestoreService.updateUserNotificationSettings(
        uid: uid,
        enabled: enabled,
      );

      final updatedUser = _userModel!.copyWith(
        settings: _userModel!.settings.copyWith(
          notificationsEnabled: enabled,
        ),
      );

      _userModel = updatedUser;
      notifyListeners();

      if (enabled) {
        await _notificationService.syncUserState(updatedUser);
      } else {
        await _notificationService.disableForCurrentUser(
          uid: uid,
          clearStoredToken: true,
        );
        await _firestoreService.updateNotificationPermissionStatus(
          uid: uid,
          status: 'disabled',
        );
      }

      await _loadUserData(uid);
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
