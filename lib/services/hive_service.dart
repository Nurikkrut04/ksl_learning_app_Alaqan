import 'package:hive_flutter/hive_flutter.dart';
import '../core/constants/app_constants.dart';

class HiveService {
  static Future<void> init() async {
    // Initialize Hive boxes
    await Hive.openBox(AppConstants.boxLessons);
    await Hive.openBox(AppConstants.boxProgress);
    await Hive.openBox(AppConstants.boxPendingSync);
    await Hive.openBox(AppConstants.boxSettings);
  }
  
  // ==================== Lessons Box ====================
  
  static Box get _lessonsBox => Hive.box(AppConstants.boxLessons);
  
  static Future<void> cacheLesson(String lessonId, Map<String, dynamic> lesson) async {
    try {
      await _lessonsBox.put(lessonId, lesson);
    } catch (e) {
      throw Exception('Error caching lesson: $e');
    }
  }
  
  static Map<String, dynamic>? getCachedLesson(String lessonId) {
    try {
      final lesson = _lessonsBox.get(lessonId);
      return lesson != null ? Map<String, dynamic>.from(lesson) : null;
    } catch (e) {
      return null;
    }
  }
  
  static Future<void> clearCachedLessons() async {
    try {
      await _lessonsBox.clear();
    } catch (e) {
      throw Exception('Error clearing cached lessons: $e');
    }
  }
  
  // ==================== Progress Box ====================
  
  static Box get _progressBox => Hive.box(AppConstants.boxProgress);
  
  static Future<void> saveProgress(String key, Map<String, dynamic> progress) async {
    try {
      await _progressBox.put(key, progress);
    } catch (e) {
      throw Exception('Error saving progress: $e');
    }
  }
  
  static Map<String, dynamic>? getProgress(String key) {
    try {
      final progress = _progressBox.get(key);
      return progress != null ? Map<String, dynamic>.from(progress) : null;
    } catch (e) {
      return null;
    }
  }
  
  static Future<void> clearProgress() async {
    try {
      await _progressBox.clear();
    } catch (e) {
      throw Exception('Error clearing progress: $e');
    }
  }
  
  // ==================== Pending Sync Box ====================
  
  static Box get _pendingSyncBox => Hive.box(AppConstants.boxPendingSync);
  
  static Future<void> addPendingSync(Map<String, dynamic> operation) async {
    try {
      final operations = _getPendingSyncOperations();
      operations.add(operation);
      await _pendingSyncBox.put('operations', operations);
    } catch (e) {
      throw Exception('Error adding pending sync: $e');
    }
  }
  
  static List<Map<String, dynamic>> _getPendingSyncOperations() {
    try {
      final operations = _pendingSyncBox.get('operations');
      if (operations == null) return [];
      return List<Map<String, dynamic>>.from(operations);
    } catch (e) {
      return [];
    }
  }
  
  static List<Map<String, dynamic>> getPendingSyncOperations() {
    return _getPendingSyncOperations();
  }
  
  static Future<void> clearPendingSync() async {
    try {
      await _pendingSyncBox.clear();
    } catch (e) {
      throw Exception('Error clearing pending sync: $e');
    }
  }
  
  static Future<void> removeSyncOperation(String operationId) async {
    try {
      final operations = _getPendingSyncOperations();
      operations.removeWhere((op) => op['id'] == operationId);
      await _pendingSyncBox.put('operations', operations);
    } catch (e) {
      throw Exception('Error removing sync operation: $e');
    }
  }
  
  // ==================== Settings Box ====================
  
  static Box get _settingsBox => Hive.box(AppConstants.boxSettings);
  
  static Future<void> saveSetting(String key, dynamic value) async {
    try {
      await _settingsBox.put(key, value);
    } catch (e) {
      throw Exception('Error saving setting: $e');
    }
  }
  
  static dynamic getSetting(String key, {dynamic defaultValue}) {
    try {
      return _settingsBox.get(key, defaultValue: defaultValue);
    } catch (e) {
      return defaultValue;
    }
  }
  
  static Future<void> clearSettings() async {
    try {
      await _settingsBox.clear();
    } catch (e) {
      throw Exception('Error clearing settings: $e');
    }
  }
  
  // ==================== Utility Methods ====================
  
  static Future<void> clearAllData() async {
    try {
      await clearCachedLessons();
      await clearProgress();
      await clearPendingSync();
      await clearSettings();
    } catch (e) {
      throw Exception('Error clearing all data: $e');
    }
  }
  
  static Future<void> close() async {
    await Hive.close();
  }
}
