import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';

String adminText(
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

Map<String, String> adminToStringMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value.map((key, val) => MapEntry(key, val.toString()));
  }

  if (value is Map) {
    return value.map((key, val) => MapEntry(key.toString(), val.toString()));
  }

  return <String, String>{};
}

String adminLocalizedValue(dynamic value, String languageCode) {
  final map = adminToStringMap(value);
  return map[languageCode] ?? map['ru'] ?? map['en'] ?? '';
}

String adminLocalizedValueForContext(dynamic value, BuildContext context) {
  return adminLocalizedValue(
    value,
    Localizations.localeOf(context).languageCode,
  );
}

String adminLanguageLabel(
  BuildContext context, {
  required String base,
  required String languageCode,
}) {
  late final String languageName;
  switch (languageCode) {
    case 'kk':
      languageName = 'KK';
      break;
    case 'ru':
      languageName = 'RU';
      break;
    case 'en':
      languageName = 'EN';
      break;
    default:
      languageName = languageCode.toUpperCase();
      break;
  }
  return '$base ($languageName)';
}

String adminRequiredFieldText(BuildContext context) {
  return adminText(
    context,
    kk: 'Бұл өріс міндетті.',
    ru: 'Это поле обязательно.',
    en: 'This field is required.',
  );
}

class AdminInfoCard extends StatelessWidget {
  final String title;
  final String body;
  final String? caption;
  final IconData icon;

  const AdminInfoCard({
    super.key,
    required this.title,
    required this.body,
    this.caption,
    this.icon = Icons.info_outline_rounded,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (caption != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      caption!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    body,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const AdminErrorCard({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              adminText(
                context,
                kk: 'Деректерді жүктеу кезінде қате шықты.',
                ru: 'Не удалось загрузить данные.',
                en: 'Failed to load data.',
              ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                adminText(
                  context,
                  kk: 'Қайта жүктеу',
                  ru: 'Повторить',
                  en: 'Retry',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminEmptyCard extends StatelessWidget {
  final String message;
  final String? actionHint;
  final IconData icon;

  const AdminEmptyCard({
    super.key,
    required this.message,
    this.actionHint,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 40, color: AppColors.textHint),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (actionHint != null) ...[
              const SizedBox(height: 8),
              Text(
                actionHint!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
