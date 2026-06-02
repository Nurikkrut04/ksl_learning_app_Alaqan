import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/colors.dart';
import '../../../services/push_campaign_service.dart';
import 'admin_ui.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _routeController = TextEditingController();
  final PushCampaignService _pushCampaignService = PushCampaignService();

  String _audience = 'all_users';
  bool _isSending = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _routeController.dispose();
    super.dispose();
  }

  Future<void> _sendCampaign() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isSending = true;
    });

    try {
      final result = await _pushCampaignService.sendCampaign(
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        audience: _audience,
        route: _routeController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.success
                ? adminText(
                    context,
                    kk:
                        'Жіберілді: ${result.successCount}/${result.targetedCount}. Жарамсыз токендер: ${result.invalidTokenCount}.',
                    ru:
                        'Отправлено: ${result.successCount}/${result.targetedCount}. Невалидных токенов: ${result.invalidTokenCount}.',
                    en:
                        'Sent: ${result.successCount}/${result.targetedCount}. Invalid tokens: ${result.invalidTokenCount}.',
                  )
                : adminText(
                    context,
                    kk: result.message.isEmpty
                        ? 'Сәйкес алушылар табылмады.'
                        : result.message,
                    ru: result.message.isEmpty
                        ? 'Подходящие получатели не найдены.'
                        : result.message,
                    en: result.message.isEmpty
                        ? 'No matching recipients were found.'
                        : result.message,
                  ),
          ),
        ),
      );

      if (result.success) {
        _titleController.clear();
        _bodyController.clear();
        _routeController.clear();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text(
            adminText(
              context,
              kk: 'Хабарламаны жіберу кезінде қате шықты: $error',
              ru: 'Не удалось отправить уведомление: $error',
              en: 'Failed to send notification: $error',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          adminText(
            context,
            kk: 'Push-рассылкалар',
            ru: 'Push-рассылки',
            en: 'Push campaigns',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AdminInfoCard(
            icon: Icons.campaign_rounded,
            title: adminText(
              context,
              kk: 'Қашықтан хабарлама жіберу',
              ru: 'Удалённая отправка уведомлений',
              en: 'Remote notification delivery',
            ),
            caption: adminText(
              context,
              kk: 'Cloud Functions + Firebase Cloud Messaging',
              ru: 'Cloud Functions + Firebase Cloud Messaging',
              en: 'Cloud Functions + Firebase Cloud Messaging',
            ),
            body: adminText(
              context,
              kk:
                  'Бұл экран хабарламаларды тікелей backend арқылы жібереді. Қабылдаушылар ретінде тек хабарламаларға рұқсат берген және өзекті push token-ы бар пайдаланушылар алынады.',
              ru:
                  'Этот экран отправляет уведомления через backend. Получателями становятся только пользователи, которые разрешили уведомления и имеют актуальный push token.',
              en:
                  'This screen sends notifications through the backend. Only users with notification permission and an active push token are targeted.',
            ),
          ),
          const SizedBox(height: 20),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      adminText(
                        context,
                        kk: 'Жаңа рассылка',
                        ru: 'Новая рассылка',
                        en: 'New campaign',
                      ),
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      adminText(
                        context,
                        kk:
                            'Қысқа тақырып пен анық мәтін қолданыңыз. Қажет болса, қолданба ішіндегі бағытты да жібере аласыз.',
                        ru:
                            'Используйте короткий заголовок и понятный текст. При необходимости можно передать и внутренний маршрут приложения.',
                        en:
                            'Use a short title and clear message. You can also include an in-app route if needed.',
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    DropdownButtonFormField<String>(
                      value: _audience,
                      decoration: InputDecoration(
                        labelText: adminText(
                          context,
                          kk: 'Аудитория',
                          ru: 'Аудитория',
                          en: 'Audience',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'all_users',
                          child: Text(_audienceLabel(context, 'all_users')),
                        ),
                        DropdownMenuItem(
                          value: 'professions_access',
                          child:
                              Text(_audienceLabel(context, 'professions_access')),
                        ),
                        DropdownMenuItem(
                          value: 'push_ready',
                          child: Text(_audienceLabel(context, 'push_ready')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _audience = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      maxLength: 120,
                      decoration: InputDecoration(
                        labelText: adminText(
                          context,
                          kk: 'Тақырып',
                          ru: 'Заголовок',
                          en: 'Title',
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return adminRequiredFieldText(context);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _bodyController,
                      maxLines: 4,
                      maxLength: 400,
                      decoration: InputDecoration(
                        labelText: adminText(
                          context,
                          kk: 'Мәтін',
                          ru: 'Текст',
                          en: 'Message',
                        ),
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return adminRequiredFieldText(context);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _routeController,
                      decoration: InputDecoration(
                        labelText: adminText(
                          context,
                          kk: 'Ішкі маршрут (міндетті емес)',
                          ru: 'Внутренний маршрут (необязательно)',
                          en: 'In-app route (optional)',
                        ),
                        hintText: '/plans',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _isSending ? null : _sendCampaign,
                        icon: _isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          adminText(
                            context,
                            kk: _isSending ? 'Жіберілуде...' : 'Жіберу',
                            ru: _isSending ? 'Отправка...' : 'Отправить',
                            en: _isSending ? 'Sending...' : 'Send',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            adminText(
              context,
              kk: 'Соңғы рассылкалар',
              ru: 'Последние рассылки',
              en: 'Recent campaigns',
            ),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('notification_campaigns')
                .orderBy('createdAt', descending: true)
                .limit(12)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return AdminErrorCard(
                  message: snapshot.error.toString(),
                  onRetry: () => setState(() {}),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 36),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs =
                  snapshot.data?.docs ?? <QueryDocumentSnapshot<Map<String, dynamic>>>[];
              if (docs.isEmpty) {
                return AdminEmptyCard(
                  icon: Icons.notifications_none_rounded,
                  message: adminText(
                    context,
                    kk: 'Әзірге жіберілген рассылкалар жоқ.',
                    ru: 'Пока нет отправленных рассылок.',
                    en: 'No campaigns have been sent yet.',
                  ),
                  actionHint: adminText(
                    context,
                    kk: 'Алғашқы хабарламаны жоғарыдағы форма арқылы жіберіңіз.',
                    ru: 'Отправьте первое уведомление через форму выше.',
                    en: 'Send your first campaign using the form above.',
                  ),
                );
              }

              return Column(
                children: docs
                    .map((doc) => _CampaignCard(data: doc.data()))
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }

  String _audienceLabel(BuildContext context, String value) {
    switch (value) {
      case 'professions_access':
        return adminText(
          context,
          kk: 'Professions қолжетімділігі барлар',
          ru: 'Пользователи с доступом к Professions',
          en: 'Users with Professions access',
        );
      case 'push_ready':
        return adminText(
          context,
          kk: 'Push қабылдауға дайын пайдаланушылар',
          ru: 'Пользователи с активным push',
          en: 'Push-ready users',
        );
      case 'all_users':
      default:
        return adminText(
          context,
          kk: 'Барлық қолжетімді пайдаланушылар',
          ru: 'Все доступные пользователи',
          en: 'All eligible users',
        );
    }
  }
}

class _CampaignCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _CampaignCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdAt = _parseDate(data['createdAt']);
    final status = (data['status'] ?? 'completed').toString();
    final title = (data['title'] ?? '').toString();
    final body = (data['body'] ?? '').toString();
    final audience = (data['audience'] ?? '').toString();
    final route = (data['route'] ?? '').toString();
    final sentByEmail = (data['sentByEmail'] ?? '').toString();
    final targetedCount = _toInt(data['targetedCount']);
    final successCount = _toInt(data['successCount']);
    final failureCount = _toInt(data['failureCount']);
    final invalidTokenCount = _toInt(data['invalidTokenCount']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                _StatusChip(status: status),
                _MetaChip(
                  icon: Icons.groups_rounded,
                  label: _audienceTitle(context, audience),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricPill(
                  icon: Icons.people_alt_rounded,
                  label: adminText(
                    context,
                    kk: 'Нысана: $targetedCount',
                    ru: 'Цель: $targetedCount',
                    en: 'Targeted: $targetedCount',
                  ),
                ),
                _MetricPill(
                  icon: Icons.check_circle_outline_rounded,
                  label: adminText(
                    context,
                    kk: 'Жеткені: $successCount',
                    ru: 'Доставлено: $successCount',
                    en: 'Delivered: $successCount',
                  ),
                ),
                _MetricPill(
                  icon: Icons.error_outline_rounded,
                  label: adminText(
                    context,
                    kk: 'Сәтсіз: $failureCount',
                    ru: 'Ошибок: $failureCount',
                    en: 'Failed: $failureCount',
                  ),
                ),
                _MetricPill(
                  icon: Icons.link_off_rounded,
                  label: adminText(
                    context,
                    kk: 'Өшірілген токендер: $invalidTokenCount',
                    ru: 'Сброшено токенов: $invalidTokenCount',
                    en: 'Invalid tokens cleared: $invalidTokenCount',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              adminText(
                context,
                kk:
                    'Жіберген: ${sentByEmail.isEmpty ? "-" : sentByEmail} • ${createdAt ?? "-"}',
                ru:
                    'Отправил: ${sentByEmail.isEmpty ? "-" : sentByEmail} • ${createdAt ?? "-"}',
                en:
                    'Sent by: ${sentByEmail.isEmpty ? "-" : sentByEmail} • ${createdAt ?? "-"}',
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            if (route.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                adminText(
                  context,
                  kk: 'Маршрут: $route',
                  ru: 'Маршрут: $route',
                  en: 'Route: $route',
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _audienceTitle(BuildContext context, String audience) {
    switch (audience) {
      case 'professions_access':
        return adminText(
          context,
          kk: 'Professions қолжетімділігі барлар',
          ru: 'Доступ к Professions',
          en: 'Professions access',
        );
      case 'push_ready':
        return adminText(
          context,
          kk: 'Push дайын',
          ru: 'Push активен',
          en: 'Push ready',
        );
      case 'all_users':
      default:
        return adminText(
          context,
          kk: 'Барлық қолжетімді',
          ru: 'Все доступные',
          en: 'All eligible',
        );
    }
  }

  static String? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('dd.MM.yyyy HH:mm').format(value.toDate());
    }
    return null;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    late final Color color;
    late final String label;

    switch (status) {
      case 'processing':
        color = AppColors.warning;
        label = adminText(
          context,
          kk: 'Орындалуда',
          ru: 'В процессе',
          en: 'Processing',
        );
        break;
      case 'failed':
        color = AppColors.error;
        label = adminText(
          context,
          kk: 'Сәтсіз',
          ru: 'Ошибка',
          en: 'Failed',
        );
        break;
      case 'skipped':
        color = AppColors.textHint;
        label = adminText(
          context,
          kk: 'Алушы табылмады',
          ru: 'Нет получателей',
          en: 'No recipients',
        );
        break;
      case 'completed':
      default:
        color = AppColors.success;
        label = adminText(
          context,
          kk: 'Аяқталды',
          ru: 'Завершено',
          en: 'Completed',
        );
        break;
    }

    return Chip(
      backgroundColor: color.withOpacity(0.10),
      label: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      side: BorderSide(color: color.withOpacity(0.18)),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: AppColors.primary),
      label: Text(label),
      side: BorderSide(color: AppColors.primary.withOpacity(0.16)),
      backgroundColor: AppColors.primary.withOpacity(0.08),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetricPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}
