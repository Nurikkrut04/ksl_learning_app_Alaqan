import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ksl_learning_app/core/constants/app_constants.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('kk'); // Default to Kazakh
  
  Locale get currentLocale => _currentLocale;
  
  String get currentLanguageCode => _currentLocale.languageCode;
  
  LanguageProvider() {
    _loadSavedLanguage();
  }
  
  // Load saved language from local storage
  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(AppConstants.keySelectedLanguage);
      
      if (savedLanguage != null && 
          AppConstants.supportedLanguages.contains(savedLanguage)) {
        _currentLocale = Locale(savedLanguage);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved language: $e');
    }
  }
  
  // Change language and save to local storage
  Future<void> changeLanguage(String languageCode) async {
    if (!AppConstants.supportedLanguages.contains(languageCode)) {
      debugPrint('Unsupported language: $languageCode');
      return;
    }
    
    _currentLocale = Locale(languageCode);
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keySelectedLanguage, languageCode);
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }
  
  // Get language name for display
  String getLanguageName(String languageCode) {
    switch (languageCode) {
      case 'kk':
        return 'Қазақша';
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      default:
        return languageCode;
    }
  }
  
  // Get all supported languages with their names
  Map<String, String> get supportedLanguagesMap => {
    'kk': 'Қазақша',
    'ru': 'Русский',
    'en': 'English',
  };
}