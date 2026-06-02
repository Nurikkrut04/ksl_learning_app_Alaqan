import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  String get currentThemeCode {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'system';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
    }
  }

  ThemeProvider() {
    _loadSavedThemeMode();
  }

  Future<void> _loadSavedThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeMode = prefs.getString(AppConstants.keyThemeMode);

      if (savedThemeMode == null) return;

      _themeMode = _themeModeFromString(savedThemeMode);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
    }
  }

  Future<void> changeThemeMode(String themeCode) async {
    final newThemeMode = _themeModeFromString(themeCode);

    if (newThemeMode == _themeMode) return;

    _themeMode = newThemeMode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyThemeMode, themeCode);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  ThemeMode _themeModeFromString(String themeCode) {
    switch (themeCode) {
      case 'system':
        return ThemeMode.system;
      case 'dark':
        return ThemeMode.dark;
      case 'light':
      default:
        return ThemeMode.light;
    }
  }
}
