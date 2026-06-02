import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../data/models/course_progress_summary.dart';
import '../../../data/models/user_model.dart';
import '../../../services/firestore_service.dart';
import 'admin_ui.dart';

class AdminUsersOverviewScreen extends StatefulWidget {
  const AdminUsersOverviewScreen({super.key});

  @override
  State<AdminUsersOverviewScreen> createState() =>
      _AdminUsersOverviewScreenState();
}

class _AdminUsersOverviewScreenState extends State<AdminUsersOverviewScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<UserModel> _users = [];
  Map<String, List<CourseProgressSummary>> _progressByUser = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final users = await _firestoreService.getAllUsers();
      final progressEntries = await Future.wait(
        users.map((user) async {
          final summaries = await _firestoreService.getUserCourseProgressSummaries(
            user.uid,
          );
          return MapEntry(user.uid, summaries);
        }),
      );

      if (!mounted) return;
      setState(() {
        _users = users;
        _progressByUser = {
          for (final entry in progressEntries) entry.key: entry.value,
        };
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<UserModel> _filteredUsers() {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _users;

    return _users.where((user) {
      return user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.role.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> _openUserDetails(UserModel user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AdminUserProgressDetailScreen(
          user: user,
          summaries: _progressByUser[user.uid] ?? const [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredUsers = _filteredUsers();
    final analytics = _buildAnalytics();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          adminText(
            context,
            kk: 'Пайдаланушылар мен прогресс',
            ru: 'Пользователи и прогресс',
            en: 'Users and progress',
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadUsers,
            tooltip: adminText(
              context,
              kk: 'Жаңарту',
              ru: 'Обновить',
              en: 'Refresh',
            ),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AdminInfoCard(
              title: adminText(
                context,
                kk: 'Пайдаланушылар аналитикасы',
                ru: 'Аналитика пользователей',
                en: 'User analytics',
              ),
              body: adminText(
                context,
                kk: 'Бұл бөлімде пайдаланушылар тізімімен қатар рөлдер, тілдер, push дайындығы, `Professions` қолжетімділігі және оқу прогресі бойынша агрегатталған метрикалар көрсетіледі.',
                ru: 'В этом разделе показываются не только пользователи, но и агрегированные метрики по ролям, языкам, push-готовности, доступу к `Professions` и учебному прогрессу.',
                en: 'This section shows both the user list and aggregated metrics for roles, languages, push readiness, `Professions` access, and learning progress.',
              ),
              icon: Icons.analytics_outlined,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
                hintText: adminText(
                  context,
                  kk: 'Аты, email немесе рөлі бойынша іздеу',
                  ru: 'Поиск по имени, email или роли',
                  en: 'Search by name, email, or role',
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              AdminErrorCard(
                message: _errorMessage!,
                onRetry: _loadUsers,
              )
            else ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _AnalyticsCard(
                    title: adminText(
                      context,
                      kk: 'Пайдаланушылар',
                      ru: 'Пользователи',
                      en: 'Users',
                    ),
                    value: analytics.totalUsers.toString(),
                    color: AppColors.categoryCulture,
                    icon: Icons.people_alt_rounded,
                  ),
                  _AnalyticsCard(
                    title: adminText(
                      context,
                      kk: 'Белсенді 7 күн',
                      ru: 'Активны 7 дней',
                      en: 'Active in 7 days',
                    ),
                    value: analytics.activeLast7Days.toString(),
                    color: AppColors.primary,
                    icon: Icons.bolt_rounded,
                  ),
                  _AnalyticsCard(
                    title: adminText(
                      context,
                      kk: 'Professions access',
                      ru: 'Доступ к Professions',
                      en: 'Professions access',
                    ),
                    value: analytics.professionsAccessCount.toString(),
                    color: AppColors.categoryProfessions,
                    icon: Icons.workspace_premium_outlined,
                  ),
                  _AnalyticsCard(
                    title: adminText(
                      context,
                      kk: 'Push дайын',
                      ru: 'Push готовы',
                      en: 'Push ready',
                    ),
                    value: analytics.pushReadyCount.toString(),
                    color: AppColors.success,
                    icon: Icons.notifications_active_outlined,
                  ),
                  _AnalyticsCard(
                    title: adminText(
                      context,
                      kk: 'Уведомления on',
                      ru: 'Уведомления on',
                      en: 'Notifications on',
                    ),
                    value: analytics.notificationsEnabledCount.toString(),
                    color: AppColors.info,
                    icon: Icons.notifications_outlined,
                  ),
                  _AnalyticsCard(
                    title: adminText(
                      context,
                      kk: 'Орташа дәлдік',
                      ru: 'Средняя точность',
                      en: 'Average accuracy',
                    ),
                    value: '${analytics.averageAccuracy}%',
                    color: AppColors.warning,
                    icon: Icons.track_changes_outlined,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adminText(
                          context,
                          kk: 'Тілдер бөлінісі',
                          ru: 'Распределение языков',
                          en: 'Language distribution',
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: analytics.languageDistribution.entries.map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              '${entry.key.toUpperCase()}: ${entry.value}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        adminText(
                          context,
                          kk: 'Топ оқушылар',
                          ru: 'Топ учащихся',
                          en: 'Top learners',
                        ),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (analytics.topLearners.isEmpty)
                        Text(
                          adminText(
                            context,
                            kk: 'Әзірге жеткілікті оқу деректері жоқ.',
                            ru: 'Пока недостаточно учебных данных.',
                            en: 'Not enough learning data yet.',
                          ),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        ...analytics.topLearners.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.primary.withOpacity(
                                    0.12,
                                  ),
                                  child: Text(
                                    '${item.rank}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.user.displayName.isEmpty
                                            ? item.user.email
                                            : item.user.displayName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        adminText(
                                          context,
                                          kk:
                                              'Сабақтар: ${item.completedLessons} | Курстар: ${item.courseCount} | Дәлдік: ${item.averageAccuracy}%',
                                          ru:
                                              'Уроки: ${item.completedLessons} | Курсы: ${item.courseCount} | Точность: ${item.averageAccuracy}%',
                                          en:
                                              'Lessons: ${item.completedLessons} | Courses: ${item.courseCount} | Accuracy: ${item.averageAccuracy}%',
                                        ),
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (filteredUsers.isEmpty)
                AdminEmptyCard(
                  message: adminText(
                    context,
                    kk: 'Сәйкес пайдаланушылар табылмады.',
                    ru: 'Подходящие пользователи не найдены.',
                    en: 'No matching users found.',
                  ),
                  actionHint: adminText(
                    context,
                    kk: 'Іздеу сұрауын өзгертіп көріңіз немесе деректерді жаңартыңыз.',
                    ru: 'Попробуйте изменить поисковый запрос или обновить данные.',
                    en: 'Try changing the search query or refresh the data.',
                  ),
                  icon: Icons.person_search_outlined,
                )
              else ...[
                Text(
                  adminText(
                    context,
                    kk: 'Көрсетілетін пайдаланушылар: ${filteredUsers.length}',
                    ru: 'Показываемые пользователи: ${filteredUsers.length}',
                    en: 'Visible users: ${filteredUsers.length}',
                  ),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                ...filteredUsers.map(
                  (user) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Card(
                      child: ListTile(
                        onTap: () => _openUserDetails(user),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 12,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: _roleColor(user).withOpacity(0.14),
                          child: Icon(
                            user.isAdmin
                                ? Icons.admin_panel_settings_rounded
                                : Icons.person_outline_rounded,
                            color: _roleColor(user),
                          ),
                        ),
                        title: Text(
                          user.displayName.isEmpty ? user.email : user.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(user.email),
                              const SizedBox(height: 4),
                              Text(
                                adminText(
                                  context,
                                  kk:
                                      'Рөлі: ${_roleLabel(context, user.role)} | Тілі: ${user.preferredLanguage.toUpperCase()} | Professions: ${_yesNo(context, user.hasProfessionsAccess)}',
                                  ru:
                                      'Роль: ${_roleLabel(context, user.role)} | Язык: ${user.preferredLanguage.toUpperCase()} | Professions: ${_yesNo(context, user.hasProfessionsAccess)}',
                                  en:
                                      'Role: ${_roleLabel(context, user.role)} | Language: ${user.preferredLanguage.toUpperCase()} | Professions: ${_yesNo(context, user.hasProfessionsAccess)}',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                adminText(
                                  context,
                                  kk:
                                      'Push: ${_pushStatusLabel(context, user)} | Соңғы кіру: ${_formatDateTime(user.lastLoginAt)}',
                                  ru:
                                      'Push: ${_pushStatusLabel(context, user)} | Последний вход: ${_formatDateTime(user.lastLoginAt)}',
                                  en:
                                      'Push: ${_pushStatusLabel(context, user)} | Last login: ${_formatDateTime(user.lastLoginAt)}',
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  _UsersAnalytics _buildAnalytics() {
    final now = DateTime.now();
    var activeLast7Days = 0;
    var professionsAccessCount = 0;
    var notificationsEnabledCount = 0;
    var pushReadyCount = 0;
    var totalAccuracy = 0;
    var usersWithAccuracy = 0;
    final languageDistribution = <String, int>{};
    final topLearners = <_TopLearner>[];

    for (final user in _users) {
      if (now.difference(user.lastLoginAt).inDays <= 7) {
        activeLast7Days += 1;
      }
      if (user.hasProfessionsAccess) {
        professionsAccessCount += 1;
      }
      if (user.settings.notificationsEnabled) {
        notificationsEnabledCount += 1;
      }
      if (_isPushReady(user)) {
        pushReadyCount += 1;
      }

      languageDistribution.update(
        user.preferredLanguage,
        (value) => value + 1,
        ifAbsent: () => 1,
      );

      final summaries = _progressByUser[user.uid] ?? const [];
      if (summaries.isNotEmpty) {
        final averageAccuracy = (summaries.fold<int>(
                  0,
                  (sum, summary) => sum + summary.averageAccuracy,
                ) /
                summaries.length)
            .round();
        totalAccuracy += averageAccuracy;
        usersWithAccuracy += 1;

        topLearners.add(
          _TopLearner(
            user: user,
            completedLessons: summaries.fold<int>(
              0,
              (sum, summary) => sum + summary.completedLessons,
            ),
            courseCount: summaries.length,
            averageAccuracy: averageAccuracy,
          ),
        );
      }
    }

    topLearners.sort((a, b) {
      final lessonCompare = b.completedLessons.compareTo(a.completedLessons);
      if (lessonCompare != 0) return lessonCompare;
      return b.averageAccuracy.compareTo(a.averageAccuracy);
    });

    final visibleTopLearners = topLearners.take(5).toList();
    final rankedLearners = <_TopLearner>[
      for (var i = 0; i < visibleTopLearners.length; i++)
        visibleTopLearners[i].copyWith(rank: i + 1),
    ];

    return _UsersAnalytics(
      totalUsers: _users.length,
      activeLast7Days: activeLast7Days,
      professionsAccessCount: professionsAccessCount,
      notificationsEnabledCount: notificationsEnabledCount,
      pushReadyCount: pushReadyCount,
      averageAccuracy:
          usersWithAccuracy == 0 ? 0 : (totalAccuracy / usersWithAccuracy).round(),
      languageDistribution: languageDistribution,
      topLearners: rankedLearners,
    );
  }

  Color _roleColor(UserModel user) {
    if (user.isAdmin) return AppColors.primary;
    if (user.hasProfessionsAccess) return AppColors.categoryProfessions;
    return AppColors.categoryCulture;
  }

  bool _isPushReady(UserModel user) {
    final status = user.notificationPermissionStatus;
    return user.settings.notificationsEnabled &&
        user.pushToken != null &&
        user.pushToken!.isNotEmpty &&
        (status == 'authorized' || status == 'provisional');
  }
}

class AdminUserProgressDetailScreen extends StatelessWidget {
  final UserModel user;
  final List<CourseProgressSummary> summaries;

  const AdminUserProgressDetailScreen({
    super.key,
    required this.user,
    required this.summaries,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final completedLessons = summaries.fold<int>(
      0,
      (sum, summary) => sum + summary.completedLessons,
    );
    final totalLessons = summaries.fold<int>(
      0,
      (sum, summary) => sum + summary.totalLessons,
    );
    final averageAccuracy = summaries.isEmpty
        ? 0
        : (summaries.fold<int>(
                  0,
                  (sum, summary) => sum + summary.averageAccuracy,
                ) /
                summaries.length)
            .round();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          adminText(
            context,
            kk: 'Пайдаланушы прогресі',
            ru: 'Прогресс пользователя',
            en: 'User progress',
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AdminInfoCard(
            title: user.displayName.isEmpty ? user.email : user.displayName,
            caption: user.email,
            body: adminText(
              context,
              kk:
                  'Рөлі: ${_roleLabel(context, user.role)} | Тілі: ${user.preferredLanguage.toUpperCase()} | Professions: ${_yesNo(context, user.hasProfessionsAccess)} | Push: ${_pushStatusLabel(context, user)}',
              ru:
                  'Роль: ${_roleLabel(context, user.role)} | Язык: ${user.preferredLanguage.toUpperCase()} | Professions: ${_yesNo(context, user.hasProfessionsAccess)} | Push: ${_pushStatusLabel(context, user)}',
              en:
                  'Role: ${_roleLabel(context, user.role)} | Language: ${user.preferredLanguage.toUpperCase()} | Professions: ${_yesNo(context, user.hasProfessionsAccess)} | Push: ${_pushStatusLabel(context, user)}',
            ),
            icon: user.isAdmin
                ? Icons.admin_panel_settings_rounded
                : Icons.person_outline_rounded,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _AnalyticsCard(
                title: adminText(
                  context,
                  kk: 'Курстар',
                  ru: 'Курсы',
                  en: 'Courses',
                ),
                value: summaries.length.toString(),
                color: AppColors.categoryFood,
                icon: Icons.menu_book_rounded,
              ),
              _AnalyticsCard(
                title: adminText(
                  context,
                  kk: 'Аяқталған сабақтар',
                  ru: 'Завершенные уроки',
                  en: 'Completed lessons',
                ),
                value: '$completedLessons / $totalLessons',
                color: AppColors.primary,
                icon: Icons.task_alt_rounded,
              ),
              _AnalyticsCard(
                title: adminText(
                  context,
                  kk: 'Орташа дәлдік',
                  ru: 'Средняя точность',
                  en: 'Average accuracy',
                ),
                value: '$averageAccuracy%',
                color: AppColors.warning,
                icon: Icons.track_changes_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (summaries.isEmpty)
            AdminEmptyCard(
              message: adminText(
                context,
                kk: 'Бұл пайдаланушыда әлі оқу прогресі жоқ.',
                ru: 'У этого пользователя пока нет учебного прогресса.',
                en: 'This user has no learning progress yet.',
              ),
              actionHint: adminText(
                context,
                kk: 'Пайдаланушы сабақтарды өткеннен кейін бұл жерде курс прогресі көрінеді.',
                ru: 'После прохождения уроков здесь появится прогресс по курсам.',
                en: 'Course progress will appear here after the user completes lessons.',
              ),
              icon: Icons.insights_outlined,
            )
          else
            ...summaries.map(
              (summary) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          summary.getTitle(languageCode),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: summary.progressValue.clamp(0.0, 1.0),
                            minHeight: 10,
                            backgroundColor: AppColors.surfaceMuted,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _levelColor(summary.levelId),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          adminText(
                            context,
                            kk:
                                'Прогресс: ${summary.progressPercent}% | Сабақтар: ${summary.completedLessons}/${summary.totalLessons} | Дәлдік: ${summary.averageAccuracy}%',
                            ru:
                                'Прогресс: ${summary.progressPercent}% | Уроки: ${summary.completedLessons}/${summary.totalLessons} | Точность: ${summary.averageAccuracy}%',
                            en:
                                'Progress: ${summary.progressPercent}% | Lessons: ${summary.completedLessons}/${summary.totalLessons} | Accuracy: ${summary.averageAccuracy}%',
                          ),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          adminText(
                            context,
                            kk:
                                'Соңғы белсенділік: ${_formatDateTime(summary.lastAccessedAt)}',
                            ru:
                                'Последняя активность: ${_formatDateTime(summary.lastAccessedAt)}',
                            en:
                                'Last activity: ${_formatDateTime(summary.lastAccessedAt)}',
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _levelColor(String levelId) {
    switch (levelId) {
      case 'beginner':
        return AppColors.beginner;
      case 'intermediate':
        return AppColors.intermediate;
      case 'advanced':
        return AppColors.advanced;
      default:
        return AppColors.primary;
    }
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final IconData icon;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.14),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UsersAnalytics {
  final int totalUsers;
  final int activeLast7Days;
  final int professionsAccessCount;
  final int notificationsEnabledCount;
  final int pushReadyCount;
  final int averageAccuracy;
  final Map<String, int> languageDistribution;
  final List<_TopLearner> topLearners;

  const _UsersAnalytics({
    required this.totalUsers,
    required this.activeLast7Days,
    required this.professionsAccessCount,
    required this.notificationsEnabledCount,
    required this.pushReadyCount,
    required this.averageAccuracy,
    required this.languageDistribution,
    required this.topLearners,
  });
}

class _TopLearner {
  final UserModel user;
  final int completedLessons;
  final int courseCount;
  final int averageAccuracy;
  final int rank;

  const _TopLearner({
    required this.user,
    required this.completedLessons,
    required this.courseCount,
    required this.averageAccuracy,
    this.rank = 0,
  });

  _TopLearner copyWith({int? rank}) {
    return _TopLearner(
      user: user,
      completedLessons: completedLessons,
      courseCount: courseCount,
      averageAccuracy: averageAccuracy,
      rank: rank ?? this.rank,
    );
  }
}

String _roleLabel(BuildContext context, String role) {
  switch (role) {
    case 'admin':
      return adminText(
        context,
        kk: 'Әкімші',
        ru: 'Администратор',
        en: 'Admin',
      );
    case 'user':
    default:
      return adminText(
        context,
        kk: 'Пайдаланушы',
        ru: 'Пользователь',
        en: 'User',
      );
  }
}

String _yesNo(BuildContext context, bool value) {
  return adminText(
    context,
    kk: value ? 'Иә' : 'Жоқ',
    ru: value ? 'Да' : 'Нет',
    en: value ? 'Yes' : 'No',
  );
}

String _pushStatusLabel(BuildContext context, UserModel user) {
  if (!user.settings.notificationsEnabled) {
    return adminText(
      context,
      kk: 'қолданбада өшірулі',
      ru: 'отключено в приложении',
      en: 'disabled in app',
    );
  }

  final hasToken = user.pushToken != null && user.pushToken!.isNotEmpty;
  switch (user.notificationPermissionStatus) {
    case 'authorized':
    case 'provisional':
      return hasToken
          ? adminText(
              context,
              kk: 'дайын',
              ru: 'готово',
              en: 'ready',
            )
          : adminText(
              context,
              kk: 'рұқсат бар, token жоқ',
              ru: 'разрешено, но нет token',
              en: 'authorized, but no token',
            );
    case 'denied':
      return adminText(
        context,
        kk: 'жүйе тыйым салған',
        ru: 'запрещено системой',
        en: 'denied by system',
      );
    case 'disabled':
      return adminText(
        context,
        kk: 'қолданбада өшірулі',
        ru: 'отключено в приложении',
        en: 'disabled in app',
      );
    default:
      return adminText(
        context,
        kk: 'тексерілмеген',
        ru: 'не определено',
        en: 'not determined',
      );
  }
}

String _formatDateTime(DateTime? value) {
  if (value == null) return '—';

  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final year = value.year.toString();
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day.$month.$year $hour:$minute';
}
