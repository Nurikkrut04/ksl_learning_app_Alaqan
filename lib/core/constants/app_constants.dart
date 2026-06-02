class AppConstants {
  // App Information
  static const String appName = 'KSL Learning';
  static const String appVersion = '1.0.0';
  
  // Supported Languages
  static const String languageKazakh = 'kk';
  static const String languageRussian = 'ru';
  static const String languageEnglish = 'en';
  
  static const List<String> supportedLanguages = [
    languageKazakh,
    languageRussian,
    languageEnglish,
  ];
  
  // User Roles
  static const String roleUser = 'user';
  static const String roleAdmin = 'admin';
  
  // Difficulty Levels
  static const String difficultyBeginner = 'beginner';
  static const String difficultyIntermediate = 'intermediate';
  static const String difficultyAdvanced = 'advanced';
  
  // Lesson Types
  static const String lessonTypeVideo = 'video';
  static const String lessonTypeInteractive = 'interactive';
  static const String lessonTypePractice = 'practice';
  
  // Quiz Question Types
  static const String questionTypeMultipleChoice = 'multipleChoice';
  static const String questionTypeTrueFalse = 'trueFalse';
  static const String questionTypeVideoMatch = 'videoMatch';
  
  // Pagination
  static const int coursesPerPage = 10;
  static const int lessonsPerPage = 20;
  
  // Cache Settings
  static const Duration cacheExpiration = Duration(days: 7);
  static const int maxCachedVideos = 20;
  
  // Quiz Settings
  static const int defaultPassingScore = 70;
  static const int defaultQuizTimeLimit = 300; // seconds
  
  // Progress Thresholds
  static const double courseCompletionThreshold = 100.0;
  static const double topicCompletionThreshold = 100.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);
  
  // Storage Keys
  static const String keyUserPreferences = 'user_preferences';
  static const String keySelectedLanguage = 'selected_language';
  static const String keyThemeMode = 'theme_mode';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String keyLastSyncTime = 'last_sync_time';
  
  // Hive Box Names
  static const String boxLessons = 'lessons_box';
  static const String boxProgress = 'progress_box';
  static const String boxPendingSync = 'pending_sync_box';
  static const String boxSettings = 'settings_box';
  
  // Error Messages
  static const String errorGeneric = 'An unexpected error occurred';
  static const String errorNetwork = 'Network error. Please check your connection';
  static const String errorAuth = 'Authentication failed';
  static const String errorPermission = 'Permission denied';
  static const String errorNotFound = 'Resource not found';
  
  // Success Messages
  static const String successSaved = 'Saved successfully';
  static const String successDeleted = 'Deleted successfully';
  static const String successUpdated = 'Updated successfully';
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  
  // Contact & Support
  static const String supportEmail = 'support@ksl-app.kz';
  static const String privacyPolicyUrl = 'https://ksl-app.kz/privacy';
  static const String termsOfServiceUrl = 'https://ksl-app.kz/terms';
}
