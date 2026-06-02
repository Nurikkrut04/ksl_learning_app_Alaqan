import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/admin_constants.dart';
import '../../../core/theme/colors.dart';
import '../../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import 'admin_courses_screen.dart';
import 'admin_notifications_screen.dart';
import 'admin_topics_screen.dart';
import 'admin_ui.dart';
import 'admin_users_overview_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = true;
  String? _errorMessage;
  int _topicCount = 0;
  int _courseCount = 0;
  int _userCount = 0;
  int _adminCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _firestoreService.getTopics(),
        _firestoreService.getAllCourses(),
        FirebaseFirestore.instance.collection('users').get(),
      ]);

      final topics = results[0] as List<Map<String, dynamic>>;
      final courses = results[1] as List<Map<String, dynamic>>;
      final usersSnapshot = results[2] as QuerySnapshot<Map<String, dynamic>>;

      final adminCount = usersSnapshot.docs.where((doc) {
        final data = doc.data();
        final email = (data['email'] ?? '').toString();
        final role = (data['role'] ?? '').toString();
        return role == 'admin' || AdminConstants.isAllowedAdminEmail(email);
      }).length;

      if (!mounted) return;

      setState(() {
        _topicCount = topics.length;
        _courseCount = courses.length;
        _userCount = usersSnapshot.size;
        _adminCount = adminCount;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final userEmail = authProvider.firebaseUser?.email ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          adminText(
            context,
            kk: 'Әкімші панелі',
            ru: 'Панель администратора',
            en: 'Admin Panel',
          ),
        ),
        actions: [
          IconButton(
            tooltip: adminText(
              context,
              kk: 'Жаңарту',
              ru: 'Обновить',
              en: 'Refresh',
            ),
            onPressed: _loadStats,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: adminText(
              context,
              kk: 'Шығу',
              ru: 'Выйти',
              en: 'Sign out',
            ),
            onPressed: () async {
              await authProvider.signOut();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _AdminHeroCard(email: userEmail),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_errorMessage != null)
              AdminErrorCard(
                message: _errorMessage!,
                onRetry: _loadStats,
              )
            else ...[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatCard(
                    title: adminText(
                      context,
                      kk: 'Тақырыптар',
                      ru: 'Темы',
                      en: 'Topics',
                    ),
                    value: _topicCount.toString(),
                    icon: Icons.dashboard_customize_rounded,
                    color: AppColors.categoryCommunication,
                  ),
                  _StatCard(
                    title: adminText(
                      context,
                      kk: 'Курстар',
                      ru: 'Курсы',
                      en: 'Courses',
                    ),
                    value: _courseCount.toString(),
                    icon: Icons.menu_book_rounded,
                    color: AppColors.categoryFood,
                  ),
                  _StatCard(
                    title: adminText(
                      context,
                      kk: 'Пайдаланушылар',
                      ru: 'Пользователи',
                      en: 'Users',
                    ),
                    value: _userCount.toString(),
                    icon: Icons.people_alt_rounded,
                    color: AppColors.categoryCulture,
                  ),
                  _StatCard(
                    title: adminText(
                      context,
                      kk: 'Әкімшілер',
                      ru: 'Администраторы',
                      en: 'Admins',
                    ),
                    value: _adminCount.toString(),
                    icon: Icons.admin_panel_settings_rounded,
                    color: AppColors.primary,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _ManagementPanel(
                onOpenTopics: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminTopicsScreen(),
                    ),
                  );
                },
                onOpenCourses: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminCoursesScreen(),
                    ),
                  );
                },
                onOpenUsers: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminUsersOverviewScreen(),
                    ),
                  );
                },
                onOpenNotifications: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminNotificationsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              _RoadmapCard(
                title: adminText(
                  context,
                  kk: 'Келесі күшейту қадамдары',
                  ru: 'Следующие шаги усиления',
                  en: 'Next improvement steps',
                ),
                items: [
                  adminText(
                    context,
                    kk:
                        'Сабақ қадамдарын raw JSON емес, ыңғайлы визуалды редактор арқылы өңдеуге көшу',
                    ru:
                        'Перейти от raw JSON к более удобному визуальному редактору шагов урока',
                    en:
                        'Replace raw JSON lesson step editing with a friendlier visual editor',
                  ),
                  adminText(
                    context,
                    kk:
                        'Медиафайлдарды админ панелінен тікелей жүктеу мүмкіндігін қосу',
                    ru:
                        'Добавить загрузку медиафайлов прямо из админ-панели',
                    en: 'Add direct media uploads from the admin panel',
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ManagementPanel extends StatelessWidget {
  final VoidCallback onOpenTopics;
  final VoidCallback onOpenCourses;
  final VoidCallback onOpenUsers;
  final VoidCallback onOpenNotifications;

  const _ManagementPanel({
    required this.onOpenTopics,
    required this.onOpenCourses,
    required this.onOpenUsers,
    required this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              adminText(
                context,
                kk: 'Басқару модульдері',
                ru: 'Модули управления',
                en: 'Management modules',
              ),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              adminText(
                context,
                kk:
                    'Мұнда контентті, пайдаланушыларды және push-рассылкаларды басқаруға болады. Курстың ішінде бөлімдер, сабақтар және тест сұрақтары қолжетімді.',
                ru:
                    'Здесь можно управлять контентом, пользователями и push-рассылками. Внутри курсов доступны разделы, уроки и тестовые вопросы.',
                en:
                    'Manage content, users, and push campaigns here. Inside each course you can work with sections, lessons, and quiz questions.',
              ),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: onOpenTopics,
                  icon: const Icon(Icons.dashboard_customize_rounded),
                  label: Text(
                    adminText(
                      context,
                      kk: 'Тақырыптар',
                      ru: 'Темы',
                      en: 'Topics',
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onOpenCourses,
                  icon: const Icon(Icons.menu_book_rounded),
                  label: Text(
                    adminText(
                      context,
                      kk: 'Курстар',
                      ru: 'Курсы',
                      en: 'Courses',
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onOpenUsers,
                  icon: const Icon(Icons.people_alt_rounded),
                  label: Text(
                    adminText(
                      context,
                      kk: 'Пайдаланушылар',
                      ru: 'Пользователи',
                      en: 'Users',
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onOpenNotifications,
                  icon: const Icon(Icons.campaign_rounded),
                  label: Text(
                    adminText(
                      context,
                      kk: 'Рассылкалар',
                      ru: 'Рассылки',
                      en: 'Campaigns',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminHeroCard extends StatelessWidget {
  final String email;

  const _AdminHeroCard({
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.16),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            adminText(
              context,
              kk: 'Әкімшіге кіру сәтті аяқталды',
              ru: 'Вход в админ-панель выполнен',
              en: 'Admin access granted',
            ),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            email,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.92),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            adminText(
              context,
              kk:
                  'Негізгі админ модульдері дайын: тақырыптар, курстар, пайдаланушылар, тесттер және push-рассылкалармен жұмыс істеуге болады.',
              ru:
                  'Основные админ-модули готовы: можно работать с темами, курсами, пользователями, тестами и push-рассылками.',
              en:
                  'The main admin modules are ready: you can manage topics, courses, users, quizzes, and push campaigns.',
            ),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withOpacity(0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 240,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.14),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 18),
              Text(
                value,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
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

class _RoadmapCard extends StatelessWidget {
  final String title;
  final List<String> items;

  const _RoadmapCard({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(top: 7),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
