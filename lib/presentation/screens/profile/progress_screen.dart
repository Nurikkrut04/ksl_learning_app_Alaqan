import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ksl_learning_app/core/localization/l10n/app_localizations.dart';

import '../../../core/theme/colors.dart';
import '../../../data/models/course_progress_summary.dart';
import '../../../presentation/providers/auth_provider.dart';
import '../../../presentation/providers/language_provider.dart';
import '../../../services/firestore_service.dart';
import '../home/sections_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> _levels = [];
  List<CourseProgressSummary> _summaries = [];

  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedTopicId;
  String? _selectedLevelId;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = context.read<AuthProvider>().firebaseUser?.uid;
      if (userId == null) {
        if (!mounted) return;
        setState(() {
          _topics = [];
          _levels = [];
          _summaries = [];
          _isLoading = false;
        });
        return;
      }

      final results = await Future.wait([
        _firestoreService.getTopics(),
        _firestoreService.getLevels(),
        _firestoreService.getUserCourseProgressSummaries(userId),
      ]);

      if (!mounted) return;

      setState(() {
        _topics = List<Map<String, dynamic>>.from(results[0] as List);
        _levels = List<Map<String, dynamic>>.from(results[1] as List);
        _summaries =
            List<CourseProgressSummary>.from(results[2] as List<CourseProgressSummary>);
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

  List<CourseProgressSummary> _filteredSummaries() {
    return _summaries.where((summary) {
      final topicMatches =
          _selectedTopicId == null || summary.topicId == _selectedTopicId;
      final levelMatches =
          _selectedLevelId == null || summary.levelId == _selectedLevelId;
      return topicMatches && levelMatches;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langCode = context.watch<LanguageProvider>().currentLanguageCode;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.myProgress),
        elevation: 0,
      ),
      body: _buildBody(l10n, langCode),
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
              onPressed: _loadProgressData,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final summaries = _filteredSummaries();

    return RefreshIndicator(
      onRefresh: _loadProgressData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _buildFilterSection(l10n, langCode),
          const SizedBox(height: 12),
          Divider(color: Theme.of(context).dividerColor),
          const SizedBox(height: 12),
          Text(
            _progressDescription(langCode),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: _secondaryTextColor(context),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          if (summaries.isEmpty)
            _EmptyProgressState(
              message: _emptyProgressMessage(langCode),
            )
          else
            ...summaries.map(
              (summary) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _ProgressCard(
                  summary: summary,
                  title: summary.getTitle(langCode),
                  averageAccuracyLabel: _averageAccuracyLabel(langCode),
                  completedLabel: _completedLabel(langCode),
                  levelColor: _getLevelColor(summary.levelId),
                  onTap: () => _openCourse(summary, langCode),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterSection(AppLocalizations l10n, String langCode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _SelectionChip(
                label: l10n.allTopics,
                selected: _selectedTopicId == null,
                onTap: () {
                  setState(() {
                    _selectedTopicId = null;
                  });
                },
              ),
              ..._topics.map((topic) {
                final topicId = (topic['id'] ?? '').toString();
                return _SelectionChip(
                  label: _localizedMapValue(topic['title'], langCode),
                  selected: _selectedTopicId == topicId,
                  onTap: () {
                    setState(() {
                      _selectedTopicId =
                          _selectedTopicId == topicId ? null : topicId;
                    });
                  },
                );
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _SelectionChip(
                label: l10n.allLevels,
                selected: _selectedLevelId == null,
                onTap: () {
                  setState(() {
                    _selectedLevelId = null;
                  });
                },
              ),
              ..._levels.map((level) {
                final levelId = (level['id'] ?? '').toString();
                return _SelectionChip(
                  label: _localizedMapValue(level['title'], langCode),
                  selected: _selectedLevelId == levelId,
                  onTap: () {
                    setState(() {
                      _selectedLevelId =
                          _selectedLevelId == levelId ? null : levelId;
                    });
                  },
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  void _openCourse(CourseProgressSummary summary, String langCode) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SectionsScreen(
          courseId: summary.courseId,
          courseTitle: summary.getTitle(langCode),
          levelId: summary.levelId,
          levelColor: _getLevelColor(summary.levelId),
        ),
      ),
    );
  }

  String _localizedMapValue(dynamic map, String langCode) {
    if (map is Map<String, dynamic>) {
      return (map[langCode] ?? map['ru'] ?? map['en'] ?? '').toString();
    }

    if (map is Map) {
      return (map[langCode] ?? map['ru'] ?? map['en'] ?? '').toString();
    }

    return '';
  }

  String _progressDescription(String langCode) {
    switch (langCode) {
      case 'kk':
        return 'Мұнда әр курс бойынша сіздің прогрессіңіз көрсетіледі.';
      case 'en':
        return 'Your progress for each course is shown here.';
      case 'ru':
      default:
        return 'Здесь отображается ваш прогресс по каждому курсу.';
    }
  }

  String _emptyProgressMessage(String langCode) {
    switch (langCode) {
      case 'kk':
        return 'Әзірге аяқталған сабақтар жоқ.';
      case 'en':
        return 'No completed lessons yet.';
      case 'ru':
      default:
        return 'Пока нет завершённых уроков.';
    }
  }

  String _averageAccuracyLabel(String langCode) {
    switch (langCode) {
      case 'kk':
        return 'Орташа дәлдік';
      case 'en':
        return 'Average accuracy';
      case 'ru':
      default:
        return 'Средняя точность';
    }
  }

  String _completedLabel(String langCode) {
    switch (langCode) {
      case 'kk':
        return 'Аяқталды';
      case 'en':
        return 'Completed';
      case 'ru':
      default:
        return 'Завершено';
    }
  }

  Color _secondaryTextColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : AppColors.textSecondary;
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

class _SelectionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SelectionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.profileAccentLight
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected
                  ? AppColors.profileAccentLight
                  : (isDark ? AppColors.borderDark : AppColors.border),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.textPrimary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final CourseProgressSummary summary;
  final String title;
  final String averageAccuracyLabel;
  final String completedLabel;
  final Color levelColor;
  final VoidCallback onTap;

  const _ProgressCard({
    required this.summary,
    required this.title,
    required this.averageAccuracyLabel,
    required this.completedLabel,
    required this.levelColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryText = isDark ? Colors.white70 : AppColors.textSecondary;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(24),
      elevation: isDark ? 0 : 2,
      shadowColor: AppColors.shadowLight,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.profileAccentLight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.hourglass_top_rounded,
                    color: levelColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: secondaryText,
                    size: 26,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: summary.progressValue.clamp(0.0, 1.0).toDouble(),
                  minHeight: 10,
                  backgroundColor:
                      isDark ? Colors.white12 : AppColors.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${summary.progressPercent}% - $averageAccuracyLabel: ${summary.averageAccuracy}%',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: secondaryText,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$completedLabel: ${summary.completedLessons} / ${summary.totalLessons}',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyProgressState extends StatelessWidget {
  final String message;

  const _EmptyProgressState({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.borderDark
              : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.insights_outlined,
            size: 40,
            color: AppColors.textHint,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white70
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
