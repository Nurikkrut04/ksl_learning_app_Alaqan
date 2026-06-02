import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ksl_learning_app/core/localization/l10n/app_localizations.dart';

import '../../../core/theme/colors.dart';
import '../../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import 'home_screen.dart';
import 'sections_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  static const String professionsTopicId = 'professions';

  final String topicId;
  final String topicTitle;
  final String levelId;
  final String levelTitle;

  const CourseDetailScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
    required this.levelId,
    required this.levelTitle,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>>? _courses;
  bool _isLoading = true;
  String? _errorMessage;

  bool get _requiresProfessionsAccess =>
      widget.topicId == CourseDetailScreen.professionsTopicId;

  @override
  void initState() {
    super.initState();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final courses = await _firestoreService.getCoursesByTopicAndLevel(
        widget.topicId,
        widget.levelId,
      );

      if (!mounted) return;
      setState(() {
        _courses = courses;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langCode = context.watch<LanguageProvider>().currentLanguageCode;
    final authProvider = context.watch<AuthProvider>();
    final isLocked =
        _requiresProfessionsAccess && !authProvider.hasProfessionsAccess;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${l10n.courses}: ${widget.topicTitle}',
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
      ),
      body: isLocked
          ? _LockedCourseState(
              title: _lockedTitle(context),
              description: _lockedBody(context),
              openPlansLabel: _openPlansText(context),
              closeLabel: _backText(context),
              onOpenPlans: _openPlans,
            )
          : _buildBody(l10n, langCode),
    );
  }

  Widget _buildBody(AppLocalizations l10n, String langCode) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(l10n.errorOccurred),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadCourses,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final courses = _courses ?? [];
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school_outlined,
              size: 64,
              color: AppColors.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.noCourses,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        final courseId = (course['id'] ?? '').toString();
        final titleMap = course['title'] as Map<String, dynamic>? ?? {};
        final descMap = course['description'] as Map<String, dynamic>? ?? {};
        final title = (titleMap[langCode] ?? titleMap['ru'] ?? '') as String;
        final description = (descMap[langCode] ?? descMap['ru'] ?? '') as String;
        final imageUrl = (course['imageUrl'] ?? '') as String;
        final levelColor = _getLevelColor(widget.levelId);

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _CourseCard(
            title: title,
            description: description,
            imageUrl: imageUrl,
            levelTitle: widget.levelTitle,
            levelColor: levelColor,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SectionsScreen(
                    courseId: courseId,
                    courseTitle: title,
                    levelId: widget.levelId,
                    levelColor: levelColor,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openPlans() async {
    await Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const HomeScreen(initialIndex: 2),
      ),
      (route) => false,
    );
  }

  String _lockedTitle(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'kk':
        return 'Курс бұғатталған';
      case 'en':
        return 'Course locked';
      case 'ru':
      default:
        return 'Курс заблокирован';
    }
  }

  String _lockedBody(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'kk':
        return 'Бұл курс арнайы жоспар арқылы ашылады. Қолжетімділікті Plans бөлімінен ашуға болады.';
      case 'en':
        return 'This course is available through a special plan. You can unlock it in the Plans section.';
      case 'ru':
      default:
        return 'Этот курс открывается через специальный план. Разблокировать его можно в разделе Plans.';
    }
  }

  String _openPlansText(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'kk':
        return 'Plans ашу';
      case 'en':
        return 'Open Plans';
      case 'ru':
      default:
        return 'Открыть Plans';
    }
  }

  String _backText(BuildContext context) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'kk':
        return 'Артқа';
      case 'en':
        return 'Back';
      case 'ru':
      default:
        return 'Назад';
    }
  }

  Color _getLevelColor(String levelId) {
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

class _CourseCard extends StatelessWidget {
  final String title;
  final String description;
  final String imageUrl;
  final String levelTitle;
  final Color levelColor;
  final VoidCallback onTap;

  const _CourseCard({
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.levelTitle,
    required this.levelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Container(
                height: 160,
                width: double.infinity,
                color: levelColor.withOpacity(0.15),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      levelTitle,
                      style: TextStyle(
                        color: levelColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onTap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        AppLocalizations.of(context)?.startLesson ?? 'Start',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
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

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.menu_book_rounded,
        size: 48,
        color: levelColor.withOpacity(0.5),
      ),
    );
  }
}

class _LockedCourseState extends StatelessWidget {
  final String title;
  final String description;
  final String openPlansLabel;
  final String closeLabel;
  final VoidCallback onOpenPlans;

  const _LockedCourseState({
    required this.title,
    required this.description,
    required this.openPlansLabel,
    required this.closeLabel,
    required this.onOpenPlans,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor:
                        AppColors.categoryProfessions.withOpacity(0.16),
                    child: const Icon(
                      Icons.lock_rounded,
                      color: AppColors.categoryProfessions,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onOpenPlans,
                      icon: const Icon(Icons.star_rounded),
                      label: Text(openPlansLabel),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(closeLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
