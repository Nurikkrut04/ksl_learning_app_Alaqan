import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../presentation/providers/auth_provider.dart';
import '../../presentation/screens/courses/courses_catalog_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/profile/progress_screen.dart';
import '../../presentation/screens/profile/settings_screen.dart';

class AppNavigator {
  AppNavigator._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static String? _pendingNotificationRoute;

  static void openNotificationRoute(String? rawRoute) {
    final route = _normalizeRoute(rawRoute);
    if (route == null) return;

    if (!_openRoute(route)) {
      _pendingNotificationRoute = route;
    }
  }

  static void flushPendingNotificationRoute() {
    final route = _pendingNotificationRoute;
    if (route == null) return;

    if (_openRoute(route)) {
      _pendingNotificationRoute = null;
    }
  }

  static bool _openRoute(String route) {
    final navigator = navigatorKey.currentState;
    final context = navigatorKey.currentContext;
    if (navigator == null || context == null) {
      return false;
    }

    final authProvider = context.read<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      return false;
    }

    final page = _pageForRoute(route);
    if (page == null) {
      debugPrint('Unsupported notification route: $route');
      return true;
    }

    navigator.push(
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );
    return true;
  }

  static Widget? _pageForRoute(String route) {
    switch (route) {
      case '/':
      case '/home':
        return const HomeScreen();
      case '/courses':
        return const CoursesCatalogScreen();
      case '/profile':
        return const ProfileScreen();
      case '/settings':
        return const SettingsScreen();
      case '/progress':
        return const ProgressScreen();
      default:
        return null;
    }
  }

  static String? _normalizeRoute(String? rawRoute) {
    final route = (rawRoute ?? '').trim();
    if (route.isEmpty) return null;

    final uri = Uri.tryParse(route);
    if (uri == null) return null;

    final path = uri.path.isEmpty ? route : uri.path;
    if (!path.startsWith('/')) {
      return '/$path';
    }
    return path;
  }
}
