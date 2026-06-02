import 'package:flutter/material.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:provider/provider.dart';
import 'package:ksl_learning_app/core/localization/l10n/app_localizations.dart';
import '../../../data/models/quiz_model.dart';
import '../../providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import 'quiz_result_dialog.dart';

class QuizScreen extends StatefulWidget {
  final String courseId;
  final String sectionId;
  final String lessonId;
  final String lessonTitle;

  const QuizScreen({
    super.key,
    required this.courseId,
    required this.sectionId,
    required this.lessonId,
    required this.lessonTitle,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<QuizQuestion> _questions = [];
  bool _isLoading = true;
  String? _error;

  // Текущий индекс вопроса в _currentQueue
  int _currentIndex = 0;

  // Очередь вопросов (на втором круге — только неправильные)
  List<int> _currentQueue = [];

  // Результаты: questionIndex → bool (правильно/неправильно)
  final Map<int, bool> _results = {};

  // Вопросы, на которые ответили неправильно (для повторного шанса)
  final List<int> _wrongOnFirstPass = [];

  // Сейчас второй круг?
  bool _isRetryRound = false;

  // Состояние текущего вопроса
  int? _selectedOptionIndex;
  bool _answered = false;

  // Видео контроллер
  CachedVideoPlayerPlusController? _videoController;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _loadQuestions() async {
    try {
      final questions = await _firestoreService.getTestsForLesson(
        widget.courseId,
        widget.sectionId,
        widget.lessonId,
      );

      if (questions.isEmpty) {
        setState(() {
          _error = 'No questions found';
          _isLoading = false;
        });
        return;
      }

      // Сортируем по order
      questions.sort((a, b) => a.order.compareTo(b.order));

      setState(() {
        _questions = questions;
        _currentQueue = List.generate(questions.length, (i) => i);
        _isLoading = false;
      });

      _initVideoForCurrentQuestion();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _initVideoForCurrentQuestion() async {
    // Освобождаем предыдущий контроллер
    await _videoController?.dispose();
    _videoController = null;
    _videoInitialized = false;

    if (_currentIndex >= _currentQueue.length) return;

    final questionIdx = _currentQueue[_currentIndex];
    final question = _questions[questionIdx];

    if (question.mediaUrl.isEmpty) return;

    try {
      final controller = CachedVideoPlayerPlusController.networkUrl(
        Uri.parse(question.mediaUrl),
      );

      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(0.0);
      controller.play();

      if (mounted) {
        setState(() {
          _videoController = controller;
          _videoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Video init error: $e');
    }
  }

  void _onOptionSelected(int optionIndex) {
    if (_answered) return;

    final questionIdx = _currentQueue[_currentIndex];
    final question = _questions[questionIdx];
    final isCorrect = question.isCorrect(optionIndex);

    setState(() {
      _selectedOptionIndex = optionIndex;
      _answered = true;
    });

    // Если первый круг и неправильно — запомнить для повтора
    if (!_isRetryRound && !isCorrect) {
      _wrongOnFirstPass.add(questionIdx);
    }

    // Записываем результат (на втором круге перезаписывает)
    _results[questionIdx] = isCorrect;

    // Через 1.5 секунды переходим к следующему вопросу
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      _goToNextQuestion();
    });
  }

  void _goToNextQuestion() {
    final nextIndex = _currentIndex + 1;

    if (nextIndex < _currentQueue.length) {
      // Есть ещё вопросы в текущем круге
      setState(() {
        _currentIndex = nextIndex;
        _selectedOptionIndex = null;
        _answered = false;
      });
      _initVideoForCurrentQuestion();
    } else if (!_isRetryRound && _wrongOnFirstPass.isNotEmpty) {
      // Первый круг закончен, есть неправильные — даём второй шанс
      setState(() {
        _isRetryRound = true;
        _currentQueue = List.from(_wrongOnFirstPass);
        _currentIndex = 0;
        _selectedOptionIndex = null;
        _answered = false;
      });
      _initVideoForCurrentQuestion();
    } else {
      // Всё, тест окончен — показываем результат
      _showResult();
    }
  }

  Future<void> _showResult() async {
    // Считаем правильные ответы
    final correct = _results.values.where((v) => v).length;
    final total = _questions.length;
    final percent = total > 0 ? ((correct / total) * 100).round() : 0;

    final userId = context.read<AuthProvider>().firebaseUser?.uid;

    _videoController?.pause();

    if (userId != null) {
      try {
        await _firestoreService.saveQuizProgress(
          userId,
          widget.courseId,
          widget.sectionId,
          widget.lessonId,
          correct,
          total,
          percent,
        );
      } catch (_) {
        // Do not block the result dialog if saving progress fails.
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => QuizResultDialog(
        correctCount: correct,
        totalCount: total,
        percent: percent,
        onOk: () {
          Navigator.of(ctx).pop(); // Закрыть диалог
          Navigator.of(context).pop(); // Вернуться на экран шагов
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final lang = Localizations.localeOf(context).languageCode;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.quiz)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.quiz)),
        body: Center(
          child: Text(_error ?? loc.noData),
        ),
      );
    }

    final questionIdx = _currentQueue[_currentIndex];
    final question = _questions[questionIdx];

    // Прогресс: общий по всем вопросам (включая retry)
    final totalInQueue = _currentQueue.length;
    final progressFraction = totalInQueue > 0
        ? (_currentIndex + 1) / totalInQueue
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lessonTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Прогресс-бар
          LinearProgressIndicator(
            value: progressFraction,
            minHeight: 4,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),

          // Тело вопроса
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Видео жеста
                  _buildVideo(),

                  const SizedBox(height: 16),

                  // Текст вопроса
                  Text(
                    question.getQuestion(lang),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),

                  // Варианты ответов
                  ...List.generate(question.options.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildOptionButton(question, i, lang),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideo() {
    if (!_videoInitialized || _videoController == null) {
      return Container(
        height: 280,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Определяем aspect ratio для вертикального видео
    final size = _videoController!.value.size;
    final isVertical = size.height > size.width;
    final aspectRatio = isVertical ? 9.0 / 16.0 : _videoController!.value.aspectRatio;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 350),
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: CachedVideoPlayerPlus(_videoController!),
        ),
      ),
    );
  }

  Widget _buildOptionButton(QuizQuestion question, int index, String lang) {
    final optionText = question.getOption(index, lang);
    final isCorrectOption = index == question.correctIndex;
    final isSelected = _selectedOptionIndex == index;

    Color? bgColor;
    Color? borderColor;
    Color textColor = Colors.black87;

    if (_answered) {
      if (isCorrectOption) {
        // Правильный ответ — всегда зелёный
        bgColor = Colors.green.shade50;
        borderColor = Colors.green;
        textColor = Colors.green.shade800;
      } else if (isSelected && !isCorrectOption) {
        // Выбранный неправильный — красный
        bgColor = Colors.red.shade50;
        borderColor = Colors.red;
        textColor = Colors.red.shade800;
      }
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _answered ? null : () => _onOptionSelected(index),
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          side: BorderSide(
            color: borderColor ?? Colors.grey.shade300,
            width: borderColor != null ? 2 : 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          optionText,
          style: TextStyle(
            fontSize: 16,
            color: textColor,
            fontWeight: borderColor != null ? FontWeight.w600 : FontWeight.normal,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
