import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:ksl_learning_app/core/localization/l10n/app_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/navigation/app_navigator.dart';
import 'presentation/providers/language_provider.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/admin/admin_gate_screen.dart';
import 'presentation/screens/home/home_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer3<LanguageProvider, AuthProvider, ThemeProvider>(
      builder: (context, languageProvider, authProvider, themeProvider, child) {
        return MaterialApp(
          title: 'Alaqan',
          debugShowCheckedModeBanner: false,
          navigatorKey: AppNavigator.navigatorKey,
          builder: (context, child) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              AppNavigator.flushPendingNotificationRoute();
            });
            return child ?? const SizedBox.shrink();
          },

          // Theme
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,

          // Localization
          locale: languageProvider.currentLocale,
          supportedLocales: const [
            Locale('kk'), // Kazakh
            Locale('ru'), // Russian
            Locale('en'), // English
          ],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          // Initial route based on auth state
          home: _isAdminWebEntry()
              ? const AdminGateScreen()
              : (authProvider.isAuthenticated
                  ? const HomeScreen()
                  : const LoginScreen()),

          // Routes will be added here
          // routes: AppRoutes.routes,
        );
      },
    );
  }

  bool _isAdminWebEntry() {
    if (!kIsWeb) return false;

    final uri = Uri.base;
    final path = uri.path.toLowerCase();
    final fragment = uri.fragment.toLowerCase();
    final mode = uri.queryParameters['mode']?.toLowerCase();

    return path.contains('/admin') ||
        fragment.contains('/admin') ||
        mode == 'admin';
  }
}
