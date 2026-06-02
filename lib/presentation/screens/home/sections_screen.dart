import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ksl_learning_app/core/localization/l10n/app_localizations.dart';

import '../../providers/language_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../services/firestore_service.dart';
import 'lessons_screen.dart';

class SectionsScreen extends StatefulWidget {
  final String courseId;
  final String courseTitle;
  final String levelId;
  final Color levelColor;

  const SectionsScreen({
    super.key,
    required this.courseId,
    required this.courseTitle,
    required this.levelId,
    required this.levelColor,
  });

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<SectionsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>>? _sections;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final sections = await _firestoreService.getSections(widget.courseId);
      if (!mounted) return;
      setState(() {
        _sections = sections;
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.courseTitle,
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
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
              onPressed: _loadSections,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final sections = _sections ?? [];
    if (sections.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_open, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'Секции не найдены',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        final sectionId = section['id'] as String;
        final titleMap = section['title'] as Map<String, dynamic>? ?? {};
        final title = (titleMap[langCode] ?? titleMap['ru'] ?? 'Секция ${index + 1}') as String;
        final totalLessons = (section['totalLessons'] ?? 0) as int;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 2,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LessonsScreen(
                      courseId: widget.courseId,
                      sectionId: sectionId,
                      sectionTitle: title,
                      levelId: widget.levelId,
                      levelColor: widget.levelColor,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Иконка секции
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: widget.levelColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: widget.levelColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Текст
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalLessons ${_lessonsWord(totalLessons)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // Стрелка
                    Icon(
                      Icons.chevron_right,
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _lessonsWord(int count) {
    if (count == 1) return 'урок';
    if (count >= 2 && count <= 4) return 'урока';
    return 'уроков';
  }
}
