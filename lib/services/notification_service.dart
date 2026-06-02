import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/navigation/app_navigator.dart';
import '../data/models/user_model.dart';
import '../firebase_options.dart';
import 'firestore_service.dart';

const String _notificationChannelId = 'learning_updates';
const String _notificationChannelName = 'Learning Updates';
const String _notificationChannelDescription =
    'Course updates and learning reminders';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Firebase may already be initialized in the background isolate.
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isInitialized = false;
  String? _currentUserId;
  bool _notificationsEnabled = true;
  bool _hasProfessionsAccess = false;

  StreamSubscription<RemoteMessage>? _foregroundMessagesSubscription;
  StreamSubscription<String>? _tokenRefreshSubscription;

  Future<void> initialize() async {
    if (_isInitialized || kIsWeb) {
      _isInitialized = true;
      return;
    }

    await _initializeLocalNotifications();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    _foregroundMessagesSubscription = FirebaseMessaging.onMessage.listen(
      _handleForegroundMessage,
    );
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);

    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedMessage(initialMessage);
    }

    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      if (_currentUserId == null || !_notificationsEnabled) return;
      await _firestoreService.saveUserPushToken(
        uid: _currentUserId!,
        token: token,
      );
    });

    _isInitialized = true;
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      defaultPresentAlert: true,
      defaultPresentBadge: true,
      defaultPresentSound: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        AppNavigator.openNotificationRoute(response.payload);
      },
    );

    const channel = AndroidNotificationChannel(
      _notificationChannelId,
      _notificationChannelName,
      description: _notificationChannelDescription,
      importance: Importance.high,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> syncUserState(UserModel user) async {
    await initialize();

    _currentUserId = user.uid;
    _notificationsEnabled = user.settings.notificationsEnabled;
    _hasProfessionsAccess = user.hasProfessionsAccess;

    if (!_notificationsEnabled) {
      await disableForCurrentUser(
        uid: user.uid,
        clearStoredToken: true,
      );
      return;
    }

    final permissionStatus = await requestPermissions();
    if (permissionStatus == null) return;

    await _firestoreService.updateNotificationPermissionStatus(
      uid: user.uid,
      status: permissionStatus,
    );

    if (permissionStatus == 'denied') {
      return;
    }

    if (kIsWeb) {
      return;
    }

    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _firestoreService.saveUserPushToken(
        uid: user.uid,
        token: token,
      );
    }

    await _syncTopicSubscriptions();
  }

  Future<void> disableForCurrentUser({
    required String uid,
    bool clearStoredToken = true,
  }) async {
    _notificationsEnabled = false;
    _currentUserId = uid;

    if (!kIsWeb) {
      await _messaging.unsubscribeFromTopic('all_users');
      await _messaging.unsubscribeFromTopic('professions_access');
      await _messaging.deleteToken();
    }

    if (clearStoredToken) {
      await _firestoreService.clearUserPushToken(uid);
    }
  }

  Future<void> detachCurrentUser() async {
    final uid = _currentUserId;
    if (uid == null) return;

    await disableForCurrentUser(
      uid: uid,
      clearStoredToken: true,
    );

    _currentUserId = null;
  }

  Future<String?> requestPermissions() async {
    if (kIsWeb) return null;

    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    switch (settings.authorizationStatus) {
      case AuthorizationStatus.authorized:
        return 'authorized';
      case AuthorizationStatus.provisional:
        return 'provisional';
      case AuthorizationStatus.denied:
        return 'denied';
      case AuthorizationStatus.notDetermined:
      default:
        return 'not_determined';
    }
  }

  Future<void> _syncTopicSubscriptions() async {
    if (kIsWeb) return;

    await _messaging.subscribeToTopic('all_users');

    if (_hasProfessionsAccess) {
      await _messaging.subscribeToTopic('professions_access');
    } else {
      await _messaging.unsubscribeFromTopic('professions_access');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (!_notificationsEnabled || kIsWeb) return;

    final notification = message.notification;
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();

    if (title == null && body == null) return;

    await _localNotifications.show(
      id: message.hashCode,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _notificationChannelId,
          _notificationChannelName,
          channelDescription: _notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: message.data['route']?.toString(),
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    debugPrint('Notification opened: ${message.messageId}');
    AppNavigator.openNotificationRoute(message.data['route']?.toString());
  }

  Future<void> dispose() async {
    await _foregroundMessagesSubscription?.cancel();
    await _tokenRefreshSubscription?.cancel();
  }
}
