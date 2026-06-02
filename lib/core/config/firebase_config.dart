import 'package:firebase_core/firebase_core.dart';

class FirebaseConfig {
  // TODO: Replace these with your actual Firebase configuration
  // Get these values from Firebase Console -> Project Settings -> Your Apps
  
  static const FirebaseOptions androidOptions = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions iosOptions = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosBundleId: 'com.example.kslLearningApp',
  );

  static FirebaseOptions get currentPlatform {
    // This will be automatically handled by flutterfire configure command
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform. '
      'Run `flutterfire configure` to generate firebase_options.dart',
    );
  }

  // Firestore settings
  static const bool enableOfflinePersistence = true;
  static const int cacheSizeBytes = 100 * 1024 * 1024; // 100 MB
}

// Instructions:
// 1. Install Firebase CLI: npm install -g firebase-tools
// 2. Install FlutterFire CLI: dart pub global activate flutterfire_cli
// 3. Login to Firebase: firebase login
// 4. Run: flutterfire configure
// 5. This will generate firebase_options.dart with your actual configuration
