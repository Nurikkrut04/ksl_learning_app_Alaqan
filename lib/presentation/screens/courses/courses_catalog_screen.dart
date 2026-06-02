import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ksl_learning_app/core/localization/l10n/app_localizations.dart';

import '../../../core/theme/colors.dart';
import '../../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../home/course_detail_screen.dart';

class CoursesCatalogScreen extends StatefulWidget {
  const CoursesCatalogScreen({super.key});

  @override
  State<CoursesCatalogScreen> createState() => _CoursesCatalogScreenState();
}

class _CoursesCatalogScreenState extends State<CoursesCatalogScreen> {
  static const int _plansPriceKzt = 5000;
  static const String _professionsTopicId = 'professions';

  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> _levels = [];
  List<Map<String, dynamic>> _allCourses = [];

  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedTopicId;
  String? _selectedLevelId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _firestoreService.getTopics(),
        _firestoreService.getLevels(),
        _firestoreService.getAllCourses(),
      ]);

      if (!mounted) return;

      setState(() {
        _topics = results[0];
        _levels = results[1];
        _allCourses = results[2];
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

  List<Map<String, dynamic>> get _filteredCourses {
    var courses = List<Map<String, dynamic>>.from(_allCourses);

    if (_selectedTopicId != null) {
      courses = courses.where((c) => c['topicId'] == _selectedTopicId).toList();
    }

    if (_selectedLevelId != null) {
      courses = courses.where((c) => c['levelId'] == _selectedLevelId).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      final langCode = context.read<LanguageProvider>().currentLanguageCode;

      courses = courses.where((c) {
        final titleMap = c['title'] as Map<String, dynamic>? ?? {};
        final descMap = c['description'] as Map<String, dynamic>? ?? {};

        final title =
            (titleMap[langCode] ?? titleMap['ru'] ?? '').toString().toLowerCase();
        final desc =
            (descMap[langCode] ?? descMap['ru'] ?? '').toString().toLowerCase();

        return title.contains(query) || desc.contains(query);
      }).toList();
    }

    return courses;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final langCode = context.watch<LanguageProvider>().currentLanguageCode;
    final authProvider = context.watch<AuthProvider>();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _buildSearchBar(l10n),
          ),
          _buildTopicFilters(l10n, langCode),
          const SizedBox(height: 4),
          _buildLevelFilters(l10n, langCode),
          const SizedBox(height: 8),
          Expanded(
            child: _buildCourseList(
              l10n: l10n,
              langCode: langCode,
              hasProfessionsAccess: authProvider.hasProfessionsAccess,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: l10n.searchCourses,
          hintStyle: const TextStyle(
            color: AppColors.textHint,
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textHint,
            size: 22,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildTopicFilters(AppLocalizations l10n, String langCode) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _FilterChip(
            label: l10n.allTopics,
            isSelected: _selectedTopicId == null,
            onTap: () {
              setState(() {
                _selectedTopicId = null;
              });
            },
          ),
          ..._topics.map((topic) {
            final topicId = topic['id'] as String;
            final titleMap = topic['title'] as Map<String, dynamic>? ?? {};
            final title = (titleMap[langCode] ?? titleMap['ru'] ?? '') as String;

            return _FilterChip(
              label: title,
              isSelected: _selectedTopicId == topicId,
              onTap: () {
                setState(() {
                  _selectedTopicId = _selectedTopicId == topicId ? null : topicId;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLevelFilters(AppLocalizations l10n, String langCode) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _FilterChip(
            label: l10n.allLevels,
            isSelected: _selectedLevelId == null,
            onTap: () {
              setState(() {
                _selectedLevelId = null;
              });
            },
          ),
          ..._levels.map((level) {
            final levelId = level['id'] as String;
            final titleMap = level['title'] as Map<String, dynamic>? ?? {};
            final title = (titleMap[langCode] ?? titleMap['ru'] ?? '') as String;

            return _FilterChip(
              label: title,
              isSelected: _selectedLevelId == levelId,
              onTap: () {
                setState(() {
                  _selectedLevelId = _selectedLevelId == levelId ? null : levelId;
                });
              },
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCourseList({
    required AppLocalizations l10n,
    required String langCode,
    required bool hasProfessionsAccess,
  }) {
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
              onPressed: _loadData,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final courses = _filteredCourses;
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

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          final isLocked = _isProfessionsLocked(
            topicId: (course['topicId'] ?? '').toString(),
            hasProfessionsAccess: hasProfessionsAccess,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _CatalogCourseCard(
              course: course,
              langCode: langCode,
              isLocked: isLocked,
              lockedLabel: _lockedBadgeText(context),
              priceLabel: _priceLabel(context),
              onTap: () => _onCourseTap(
                course: course,
                langCode: langCode,
                hasProfessionsAccess: hasProfessionsAccess,
              ),
            ),
          );
        },
      ),
    );
  }

  void _onCourseTap({
    required Map<String, dynamic> course,
    required String langCode,
    required bool hasProfessionsAccess,
  }) {
    final topicId = (course['topicId'] ?? '').toString();
    if (_isProfessionsLocked(
      topicId: topicId,
      hasProfessionsAccess: hasProfessionsAccess,
    )) {
      _showLockedDialog();
      return;
    }

    final levelId = (course['levelId'] ?? '').toString();

    String levelTitle = '';
    for (final level in _levels) {
      if (level['id'] == levelId) {
        final levelTitleMap = level['title'] as Map<String, dynamic>? ?? {};
        levelTitle =
            (levelTitleMap[langCode] ?? levelTitleMap['ru'] ?? '') as String;
        break;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CourseDetailScreen(
          topicId: topicId,
          topicTitle: _getTopicTitle(topicId, langCode),
          levelId: levelId,
          levelTitle: levelTitle,
        ),
      ),
    );
  }

  Future<void> _showLockedDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_lockedTitle(context)),
        content: Text(_lockedBody(context)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_closeText(context)),
          ),
        ],
      ),
    );
  }

  bool _isProfessionsLocked({
    required String topicId,
    required bool hasProfessionsAccess,
  }) {
    return topicId == _professionsTopicId && !hasProfessionsAccess;
  }

  String _getTopicTitle(String topicId, String langCode) {
    for (final topic in _topics) {
      if (topic['id'] == topicId) {
        final titleMap = topic['title'] as Map<String, dynamic>? ?? {};
        return (titleMap[langCode] ?? titleMap['ru'] ?? '') as String;
      }
    }
    return '';
  }

  String _priceLabel(BuildContext context) {
    return _text(
      context,
      kk: '$_plansPriceKzt тг',
      ru: '$_plansPriceKzt тг',
      en: '$_plansPriceKzt KZT',
    );
  }

  String _lockedBadgeText(BuildContext context) {
    return _text(
      context,
      kk: 'Жазылым',
      ru: 'Подписка',
      en: 'Subscription',
    );
  }

  String _lockedTitle(BuildContext context) {
    return _text(
      context,
      kk: 'Курс бұғатталған',
      ru: 'Курс заблокирован',
      en: 'Course locked',
    );
  }

  String _lockedBody(BuildContext context) {
    return _text(
      context,
      kk:
          'Бұл курс жазылымнан кейін қолжетімді болады. Қолжетімділікті Plans қойындысынан $_plansPriceKzt тг бағасымен аша аласыз.',
      ru:
          'Этот курс будет доступен при подписке. Разблокировать его можно во вкладке Plans за $_plansPriceKzt тг.',
      en:
          'This course is available with a subscription. You can unlock it in the Plans tab for $_plansPriceKzt KZT.',
    );
  }

  String _closeText(BuildContext context) {
    return _text(
      context,
      kk: 'Жабу',
      ru: 'Закрыть',
      en: 'Close',
    );
  }

  String _text(
    BuildContext context, {
    required String kk,
    required String ru,
    required String en,
  }) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'kk':
        return kk;
      case 'en':
        return en;
      case 'ru':
      default:
        return ru;
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.border),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 16,
                  color: AppColors.textWhite,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.textWhite
                      : theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogCourseCard extends StatelessWidget {
  final Map<String, dynamic> course;
  final String langCode;
  final bool isLocked;
  final String lockedLabel;
  final String priceLabel;
  final VoidCallback onTap;

  const _CatalogCourseCard({
    required this.course,
    required this.langCode,
    required this.isLocked,
    required this.lockedLabel,
    required this.priceLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryText = isDark ? Colors.white70 : AppColors.textSecondary;

    final titleMap = course['title'] as Map<String, dynamic>? ?? {};
    final descMap = course['description'] as Map<String, dynamic>? ?? {};
    final title = (titleMap[langCode] ?? titleMap['ru'] ?? '') as String;
    final description = (descMap[langCode] ?? descMap['ru'] ?? '') as String;
    final imageUrl = (course['imageUrl'] ?? '') as String;
    final levelId = (course['levelId'] ?? '') as String;
    final levelColor = _getLevelColor(levelId);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? AppColors.shadowDark : AppColors.shadowLight,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    color: levelColor.withOpacity(0.12),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _buildPlaceholder(levelColor),
                          )
                        : _buildPlaceholder(levelColor),
                  ),
                  if (isLocked)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.72),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.lock_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              lockedLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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
                      _getLevelLabel(levelId),
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: secondaryText,
                    ),
                  ),
                  if (isLocked) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: AppColors.secondaryDark,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          priceLabel,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: AppColors.secondaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(Color color) {
    return Center(
      child: Icon(
        Icons.menu_book_rounded,
        size: 48,
        color: color.withOpacity(0.5),
      ),
    );
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

  String _getLevelLabel(String levelId) {
    switch (levelId) {
      case 'beginner':
        return 'Beginner';
      case 'intermediate':
        return 'Intermediate';
      case 'advanced':
        return 'Advanced';
      default:
        return levelId;
    }
  }
}
