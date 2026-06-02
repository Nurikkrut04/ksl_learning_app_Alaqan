import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ksl_learning_app/core/localization/l10n/app_localizations.dart';

import '../../../core/theme/colors.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/language_provider.dart';
import '../../../presentation/providers/theme_provider.dart';
import '../../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();

  late TextEditingController _usernameController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;

  int _selectedAvatarIndex = 0;
  bool _isSaving = false;

  static const List<String> _avatarAssets = [
    'assets/images/avatar_1.png',
    'assets/images/avatar_2.png',
    'assets/images/avatar_3.png',
    'assets/images/avatar_4.png',
    'assets/images/avatar_5.png',
    'assets/images/avatar_6.png',
  ];

  static const Color _purple = AppColors.profileAccent;
  static const Color _purpleLight = AppColors.profileAccentLight;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userModel;

    _usernameController = TextEditingController(text: user?.displayName ?? '');
    _firstNameController = TextEditingController(text: user?.displayName ?? '');
    _lastNameController = TextEditingController();

    if (user?.avatarUrl != null) {
      final idx = _avatarAssets.indexOf(user!.avatarUrl!);
      if (idx >= 0) {
        _selectedAvatarIndex = idx;
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langProvider = context.watch<LanguageProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenBackground = theme.scaffoldBackgroundColor;
    final cardBackground = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;
    final subduedText =
        isDark ? Colors.white70 : AppColors.textSecondary;
    final fieldFillColor =
        isDark ? AppColors.backgroundDark : AppColors.surfaceMuted;
    final cardShadowColor =
        isDark ? Colors.black.withOpacity(0.24) : Colors.black.withOpacity(0.04);

    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        backgroundColor: cardBackground,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: onSurface),
        ),
        title: Text(
          l10n.settings,
          style: TextStyle(
            color: onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text(
              l10n.save,
              style: TextStyle(
                color: _isSaving ? AppColors.textHint : AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: cardShadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _avatarAssets.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _selectedAvatarIndex;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAvatarIndex = index;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _purpleLight.withOpacity(0.5),
                              border: Border.all(
                                color:
                                    isSelected ? _purple : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: Stack(
                              children: [
                                ClipOval(
                                  child: Image.asset(
                                    _avatarAssets[index],
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 70,
                                      height: 70,
                                      color: _purpleLight,
                                      child: Icon(
                                        Icons.person,
                                        color: _purple.withOpacity(0.5),
                                        size: 32,
                                      ),
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SettingsTextField(
                    label: l10n.username,
                    controller: _usernameController,
                    fillColor: fieldFillColor,
                    labelColor: subduedText,
                    textColor: onSurface,
                  ),
                  const SizedBox(height: 12),
                  _SettingsTextField(
                    label: l10n.firstName,
                    controller: _firstNameController,
                    fillColor: fieldFillColor,
                    labelColor: subduedText,
                    textColor: onSurface,
                  ),
                  const SizedBox(height: 12),
                  _SettingsTextField(
                    label: l10n.lastName,
                    controller: _lastNameController,
                    fillColor: fieldFillColor,
                    labelColor: subduedText,
                    textColor: onSurface,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: cardShadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 6,
                ),
                leading: Icon(
                  Icons.lock_outline_rounded,
                  color: subduedText,
                ),
                title: Text(
                  l10n.changePassword,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: onSurface,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: subduedText,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onTap: () => _showChangePasswordDialog(context, l10n),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: cardShadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.language_rounded,
                    color: subduedText,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: langProvider.currentLanguageCode,
                        isExpanded: true,
                        dropdownColor: cardBackground,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: subduedText,
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: onSurface,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'kk',
                            child: Text(l10n.kazakh),
                          ),
                          DropdownMenuItem(
                            value: 'ru',
                            child: Text(l10n.russian),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Text(l10n.english),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            langProvider.changeLanguage(value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: cardShadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.dark_mode_outlined,
                    color: subduedText,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: themeProvider.currentThemeCode,
                        isExpanded: true,
                        dropdownColor: cardBackground,
                        icon: Icon(
                          Icons.arrow_drop_down,
                          color: subduedText,
                        ),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: onSurface,
                        ),
                        items: [
                          DropdownMenuItem(
                            value: 'system',
                            child: Text(l10n.themeSystem),
                          ),
                          DropdownMenuItem(
                            value: 'light',
                            child: Text(l10n.themeLight),
                          ),
                          DropdownMenuItem(
                            value: 'dark',
                            child: Text(l10n.themeDark),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            themeProvider.changeThemeMode(value);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: cardBackground,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: cardShadowColor,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Icon(
                      Icons.notifications_outlined,
                      color: subduedText,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _notificationsTitle(context),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _notificationsDescription(
                            context,
                            authProvider.notificationPermissionStatus,
                            authProvider.notificationsEnabled,
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: subduedText,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _notificationStatusLabel(
                            context,
                            authProvider.notificationPermissionStatus,
                            authProvider.notificationsEnabled,
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _notificationStatusColor(
                              authProvider.notificationPermissionStatus,
                              authProvider.notificationsEnabled,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: authProvider.notificationsEnabled,
                    onChanged: authProvider.isLoading
                        ? null
                        : (value) async {
                            final success = await authProvider
                                .updateNotificationsEnabled(value);

                            if (!mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? _notificationsSavedText(context)
                                      : _notificationsFailedText(context),
                                ),
                                backgroundColor: success
                                    ? AppColors.success
                                    : AppColors.error,
                              ),
                            );
                          },
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final authProvider = context.read<AuthProvider>();
                    await authProvider.signOut();

                    if (context.mounted) {
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(
                    l10n.signOut,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    final success = await authProvider.updateProfile(
      displayName: _usernameController.text.trim(),
      avatarUrl: _avatarAssets[_selectedAvatarIndex],
    );

    if (!mounted) return;

    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? l10n.updateSuccess : l10n.updateFailed),
        backgroundColor: success ? AppColors.success : AppColors.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showChangePasswordDialog(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.changePassword),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.newPassword,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.confirmPassword,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPass = newPasswordController.text.trim();
              final confirmPass = confirmPasswordController.text.trim();

              if (newPass.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.passwordTooShort)),
                );
                return;
              }

              if (newPass != confirmPass) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.passwordsDoNotMatch)),
                );
                return;
              }

              try {
                await _authService.updatePassword(newPass);

                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.updateSuccess),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.updateFailed),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  String _notificationsTitle(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'kk':
        return 'Push хабарламалар';
      case 'ru':
        return 'Push-уведомления';
      case 'en':
      default:
        return 'Push notifications';
    }
  }

  String _notificationsDescription(
    BuildContext context,
    String permissionStatus,
    bool enabled,
  ) {
    if (!enabled) {
      switch (Localizations.localeOf(context).languageCode) {
        case 'kk':
          return 'Хабарламалар өшірілген. Қоссаңыз, қолданба курс жаңартулары мен ескертпелерді ала алады.';
        case 'ru':
          return 'Уведомления отключены. После включения приложение сможет получать обновления курсов и напоминания.';
        case 'en':
        default:
          return 'Notifications are disabled. When enabled, the app can receive course updates and reminders.';
      }
    }

    switch (permissionStatus) {
      case 'authorized':
      case 'provisional':
        switch (Localizations.localeOf(context).languageCode) {
          case 'kk':
            return 'Хабарламалар қосулы. Қолданба foreground режимінде push-тарды көрсетеді және FCM token-ды сақтайды.';
          case 'ru':
            return 'Уведомления включены. Приложение будет показывать push-сообщения в foreground и сохранять FCM token.';
          case 'en':
          default:
            return 'Notifications are enabled. The app will display foreground pushes and store the FCM token.';
        }
      case 'denied':
        switch (Localizations.localeOf(context).languageCode) {
          case 'kk':
            return 'Құрылғы рұқсаты өшірулі. Толық push алу үшін жүйе баптауларынан рұқсат беру қажет.';
          case 'ru':
            return 'Разрешение устройства отключено. Для полноценного получения push нужно разрешить уведомления в системных настройках.';
          case 'en':
          default:
            return 'Device permission is disabled. Enable notifications in system settings for full push delivery.';
        }
      default:
        switch (Localizations.localeOf(context).languageCode) {
          case 'kk':
            return 'Хабарламаларға рұқсат сұралады және token тіркеледі.';
          case 'ru':
            return 'Будет запрошено разрешение на уведомления и зарегистрирован token.';
          case 'en':
          default:
            return 'Notification permission will be requested and the token will be registered.';
        }
    }
  }

  String _notificationStatusLabel(
    BuildContext context,
    String permissionStatus,
    bool enabled,
  ) {
    if (!enabled) {
      switch (Localizations.localeOf(context).languageCode) {
        case 'kk':
          return 'Күйі: өшірулі';
        case 'ru':
          return 'Статус: отключено';
        case 'en':
        default:
          return 'Status: disabled';
      }
    }

    switch (permissionStatus) {
      case 'authorized':
        switch (Localizations.localeOf(context).languageCode) {
          case 'kk':
            return 'Күйі: рұқсат берілген';
          case 'ru':
            return 'Статус: разрешено';
          case 'en':
          default:
            return 'Status: authorized';
        }
      case 'provisional':
        switch (Localizations.localeOf(context).languageCode) {
          case 'kk':
            return 'Күйі: шектеулі рұқсат';
          case 'ru':
            return 'Статус: ограниченное разрешение';
          case 'en':
          default:
            return 'Status: provisional';
        }
      case 'denied':
        switch (Localizations.localeOf(context).languageCode) {
          case 'kk':
            return 'Күйі: жүйе деңгейінде тыйым салынған';
          case 'ru':
            return 'Статус: запрещено на уровне системы';
          case 'en':
          default:
            return 'Status: denied by system';
        }
      case 'disabled':
        switch (Localizations.localeOf(context).languageCode) {
          case 'kk':
            return 'Күйі: қолданба ішінде өшірулі';
          case 'ru':
            return 'Статус: отключено в приложении';
          case 'en':
          default:
            return 'Status: disabled in app';
        }
      default:
        switch (Localizations.localeOf(context).languageCode) {
          case 'kk':
            return 'Күйі: тексерілмеген';
          case 'ru':
            return 'Статус: не определён';
          case 'en':
          default:
            return 'Status: not determined';
        }
    }
  }

  Color _notificationStatusColor(String permissionStatus, bool enabled) {
    if (!enabled) return AppColors.textSecondary;
    switch (permissionStatus) {
      case 'authorized':
      case 'provisional':
        return AppColors.success;
      case 'denied':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _notificationsSavedText(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'kk':
        return 'Хабарлама параметрлері сақталды.';
      case 'ru':
        return 'Настройки уведомлений сохранены.';
      case 'en':
      default:
        return 'Notification settings saved.';
    }
  }

  String _notificationsFailedText(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'kk':
        return 'Хабарлама параметрлерін сақтау сәтсіз аяқталды.';
      case 'ru':
        return 'Не удалось сохранить настройки уведомлений.';
      case 'en':
      default:
        return 'Failed to save notification settings.';
    }
  }
}

class _SettingsTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final Color fillColor;
  final Color labelColor;
  final Color textColor;

  const _SettingsTextField({
    required this.label,
    required this.controller,
    required this.fillColor,
    required this.labelColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: labelColor,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                color: AppColors.profileAccent,
                width: 1.5,
              ),
            ),
          ),
          style: TextStyle(
            fontSize: 16,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
