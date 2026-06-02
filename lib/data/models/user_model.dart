import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String role;
  final String preferredLanguage;
  final String? avatarUrl;
  final bool hasProfessionsAccess;
  final String? pushToken;
  final String notificationPermissionStatus;
  final DateTime? pushTokenUpdatedAt;
  final DateTime createdAt;
  final DateTime lastLoginAt;
  final bool isOnline;
  final UserSettings settings;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.preferredLanguage,
    this.avatarUrl,
    this.hasProfessionsAccess = false,
    this.pushToken,
    this.notificationPermissionStatus = 'unknown',
    this.pushTokenUpdatedAt,
    required this.createdAt,
    required this.lastLoginAt,
    this.isOnline = false,
    required this.settings,
  });

  /// Безопасный парсинг timestamp из Firestore.
  /// FieldValue.serverTimestamp() может вернуть null до синхронизации с сервером.
  static DateTime _parseTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return DateTime.now();
  }

  static DateTime? _parseOptionalTimestamp(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }

  // Factory constructor from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: data['role'] ?? 'user',
      preferredLanguage: data['preferredLanguage'] ?? 'kk',
      avatarUrl: data['avatarUrl'],
      hasProfessionsAccess: data['hasProfessionsAccess'] ?? false,
      pushToken: data['pushToken'] as String?,
      notificationPermissionStatus:
          data['notificationPermissionStatus'] ?? 'unknown',
      pushTokenUpdatedAt: _parseOptionalTimestamp(data['pushTokenUpdatedAt']),
      createdAt: _parseTimestamp(data['createdAt']),
      lastLoginAt: _parseTimestamp(data['lastLoginAt']),
      isOnline: data['isOnline'] ?? false,
      settings: UserSettings.fromMap(data['settings'] ?? {}),
    );
  }

  // Factory constructor from Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      role: map['role'] ?? 'user',
      preferredLanguage: map['preferredLanguage'] ?? 'kk',
      avatarUrl: map['avatarUrl'],
      hasProfessionsAccess: map['hasProfessionsAccess'] ?? false,
      pushToken: map['pushToken'] as String?,
      notificationPermissionStatus:
          map['notificationPermissionStatus'] ?? 'unknown',
      pushTokenUpdatedAt: _parseOptionalTimestamp(map['pushTokenUpdatedAt']),
      createdAt: _parseTimestamp(map['createdAt']),
      lastLoginAt: _parseTimestamp(map['lastLoginAt']),
      isOnline: map['isOnline'] ?? false,
      settings: UserSettings.fromMap(map['settings'] ?? {}),
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role,
      'preferredLanguage': preferredLanguage,
      'avatarUrl': avatarUrl,
      'hasProfessionsAccess': hasProfessionsAccess,
      'pushToken': pushToken,
      'notificationPermissionStatus': notificationPermissionStatus,
      'pushTokenUpdatedAt':
          pushTokenUpdatedAt == null ? null : Timestamp.fromDate(pushTokenUpdatedAt!),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'isOnline': isOnline,
      'settings': settings.toMap(),
    };
  }

  // Check if user is admin
  bool get isAdmin => role == 'admin';

  // Copy with method for immutability
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    String? preferredLanguage,
    String? avatarUrl,
    bool? hasProfessionsAccess,
    String? pushToken,
    String? notificationPermissionStatus,
    DateTime? pushTokenUpdatedAt,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isOnline,
    UserSettings? settings,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      hasProfessionsAccess:
          hasProfessionsAccess ?? this.hasProfessionsAccess,
      pushToken: pushToken ?? this.pushToken,
      notificationPermissionStatus:
          notificationPermissionStatus ?? this.notificationPermissionStatus,
      pushTokenUpdatedAt: pushTokenUpdatedAt ?? this.pushTokenUpdatedAt,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isOnline: isOnline ?? this.isOnline,
      settings: settings ?? this.settings,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        role,
        preferredLanguage,
        avatarUrl,
        hasProfessionsAccess,
        pushToken,
        notificationPermissionStatus,
        pushTokenUpdatedAt,
        createdAt,
        lastLoginAt,
        isOnline,
        settings,
      ];
}

class UserSettings extends Equatable {
  final bool notificationsEnabled;
  final bool offlineMode;
  final String theme;

  const UserSettings({
    this.notificationsEnabled = true,
    this.offlineMode = true,
    this.theme = 'light',
  });

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      offlineMode: map['offlineMode'] ?? true,
      theme: map['theme'] ?? 'light',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'notificationsEnabled': notificationsEnabled,
      'offlineMode': offlineMode,
      'theme': theme,
    };
  }

  UserSettings copyWith({
    bool? notificationsEnabled,
    bool? offlineMode,
    String? theme,
  }) {
    return UserSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      offlineMode: offlineMode ?? this.offlineMode,
      theme: theme ?? this.theme,
    );
  }

  @override
  List<Object?> get props => [notificationsEnabled, offlineMode, theme];
}
