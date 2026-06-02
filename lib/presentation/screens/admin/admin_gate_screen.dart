import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/admin_constants.dart';
import '../../providers/auth_provider.dart';
import 'admin_dashboard_screen.dart';

class AdminGateScreen extends StatefulWidget {
  const AdminGateScreen({super.key});

  @override
  State<AdminGateScreen> createState() => _AdminGateScreenState();
}

class _AdminGateScreenState extends State<AdminGateScreen> {
  bool _handledUnauthorizedUser = false;
  String? _deniedEmail;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    if (authProvider.isLoading) {
      return _AdminShell(
        child: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    if (!authProvider.isAuthenticated) {
      if (_deniedEmail != null) {
        return _AdminShell(
          child: _AccessDeniedCard(
            email: _deniedEmail!,
            onTryAgain: () {
              setState(() {
                _deniedEmail = null;
              });
            },
          ),
        );
      }

      return _AdminShell(
        child: _AdminSignInCard(
          onSignIn: authProvider.signInWithGoogle,
        ),
      );
    }

    if (authProvider.hasAdminAccess) {
      _handledUnauthorizedUser = false;
      _deniedEmail = null;
      return const AdminDashboardScreen();
    }

    final email = authProvider.firebaseUser?.email ?? '';
    final isKnownAdminEmail = AdminConstants.isAllowedAdminEmail(email);

    if (!_handledUnauthorizedUser && !isKnownAdminEmail) {
      _handledUnauthorizedUser = true;
      _deniedEmail = email;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await authProvider.signOut();
      });
    }

    return _AdminShell(
      child: _AccessDeniedCard(
        email: email,
      ),
    );
  }
}

class _AdminShell extends StatelessWidget {
  final Widget child;

  const _AdminShell({
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withOpacity(0.10),
              theme.scaffoldBackgroundColor,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminSignInCard extends StatelessWidget {
  final Future<bool> Function() onSignIn;

  const _AdminSignInCard({
    required this.onSignIn,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: theme.colorScheme.primary.withOpacity(0.12),
              child: Icon(
                Icons.admin_panel_settings_rounded,
                color: theme.colorScheme.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _localizedText(
                context,
                kk: 'Әкімші панелі',
                ru: 'Панель администратора',
                en: 'Admin Panel',
              ),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _localizedText(
                context,
                kk: 'Кіру тек рұқсат етілген Google аккаунттары арқылы жүзеге асады.',
                ru: 'Вход доступен только через разрешённые Google-аккаунты.',
                en: 'Sign-in is available only for approved Google accounts.',
              ),
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await onSignIn();
                },
                icon: const Icon(Icons.login_rounded),
                label: Text(
                  _localizedText(
                    context,
                    kk: 'Google арқылы кіру',
                    ru: 'Войти через Google',
                    en: 'Sign in with Google',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              _localizedText(
                context,
                kk: 'Қазіргі рұқсат етілген аккаунт: nurikslam.beis@gmail.com',
                ru: 'Сейчас разрешённый аккаунт: nurikslam.beis@gmail.com',
                en: 'Currently allowed account: nurikslam.beis@gmail.com',
              ),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccessDeniedCard extends StatelessWidget {
  final String email;
  final VoidCallback? onTryAgain;

  const _AccessDeniedCard({
    required this.email,
    this.onTryAgain,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.red.withOpacity(0.12),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Colors.red,
                size: 30,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _localizedText(
                context,
                kk: 'Қол жеткізуге тыйым салынған',
                ru: 'Доступ запрещён',
                en: 'Access denied',
              ),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _localizedText(
                context,
                kk: 'Бұл админ-панельге тек рұқсат етілген Google аккаунттары кіре алады.',
                ru: 'В эту админ-панель могут входить только разрешённые Google-аккаунты.',
                en: 'Only approved Google accounts can access this admin panel.',
              ),
              style: theme.textTheme.bodyLarge,
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Email: $email',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (onTryAgain != null) ...[
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onTryAgain,
                  child: Text(
                    _localizedText(
                      context,
                      kk: 'Басқа аккаунтпен кіру',
                      ru: 'Войти с другим аккаунтом',
                      en: 'Try another account',
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _localizedText(
  BuildContext context, {
  required String kk,
  required String ru,
  required String en,
}) {
  final locale = Localizations.localeOf(context).languageCode;
  switch (locale) {
    case 'kk':
      return kk;
    case 'en':
      return en;
    case 'ru':
    default:
      return ru;
  }
}
