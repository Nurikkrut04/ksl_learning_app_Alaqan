import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ksl_learning_app/core/localization/l10n/app_localizations.dart';

import '../../providers/language_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../services/firestore_service.dart';
import 'lesson_steps_screen.dart';

class LessonsScreen extends StatefulWidget {
  final String courseId;
  final String sectionId;
  final String sectionTitle;
  final String levelId;
  final Color levelColor;

  const LessonsScreen({
    super.key,
    required this.courseId,
    required this.sectionId,
    required this.sectionTitle,
    required this.levelId,
    required this.levelColor,
  });

  @override
  State<LessonsScreen> createState() => _LessonsScreenState();
}

class _LessonsScreenState extends State<LessonsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>>? _lessons;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLessons();
  }

  Future<void> _loadLessons() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final lessons = await _firestoreService.getLessonsBySection(
        widget.courseId,
        widget.sectionId,
      );
      if (!mounted) return;
      setState(() {
        _lessons = lessons;
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
          widget.sectionTitle,
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
              onPressed: _loadLessons,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final lessons = _lessons ?? [];
    if (lessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.book_outlined, size: 64, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              'Уроки не найдены',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        final lessonId = lesson['id'] as String;
        final titleMap = lesson['title'] as Map<String, dynamic>? ?? {};
        final title = (titleMap[langCode] ?? titleMap['ru'] ?? 'Урок ${index + 1}') as String;

        // Получаем steps для подсчёта
        final steps = lesson['steps'] as List<dynamic>? ?? [];
        final stepsCount = steps.length;

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
                    builder: (_) => LessonStepsScreen(
                      courseId: widget.courseId,
                      sectionId: widget.sectionId,
                      lessonId: lessonId,
                      lessonTitle: title,
                      steps: List<Map<String, dynamic>>.from(
                        steps.map((s) => Map<String, dynamic>.from(s as Map)),
                      ),
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
                    // Иконка урока
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: widget.levelColor.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.play_arrow_rounded,
                          color: widget.levelColor,
                          size: 28,
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
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$stepsCount ${_stepsWord(stepsCount)}',
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

  String _stepsWord(int count) {
    if (count == 1) return 'шаг';
    if (count >= 2 && count <= 4) return 'шага';
    return 'шагов';
  }
}
