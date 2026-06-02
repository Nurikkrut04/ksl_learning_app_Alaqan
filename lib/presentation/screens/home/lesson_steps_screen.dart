import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:ksl_learning_app/core/localization/l10n/app_localizations.dart';

import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../services/firestore_service.dart';
import '../quiz/quiz_screen.dart';

class LessonStepsScreen extends StatefulWidget {
  final String courseId;
  final String sectionId;
  final String lessonId;
  final String lessonTitle;
  final List<Map<String, dynamic>> steps;
  final Color levelColor;

  const LessonStepsScreen({
    super.key,
    required this.courseId,
    required this.sectionId,
    required this.lessonId,
    required this.lessonTitle,
    required this.steps,
    required this.levelColor,
  });

  @override
  State<LessonStepsScreen> createState() => _LessonStepsScreenState();
}

class _LessonStepsScreenState extends State<LessonStepsScreen>
    with WidgetsBindingObserver {
  final FirestoreService _firestoreService = FirestoreService();

  int _currentStep = 0;
  bool _lessonCompleted = false;

  CachedVideoPlayerPlusController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;
  double _playbackSpeed = 0.5;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    widget.steps.sort((a, b) {
      final orderA = (a['order'] ?? 0) as int;
      final orderB = (b['order'] ?? 0) as int;
      return orderA.compareTo(orderB);
    });

    _loadCompletionState();
    _initVideoIfNeeded();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeVideoController();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _videoController?.pause();
    } else if (state == AppLifecycleState.resumed) {
      if (_isVideoInitialized && _videoController != null) {
        _videoController!.play();
      }
    }
  }

  Future<void> _disposeVideoController() async {
    final controller = _videoController;
    if (controller != null) {
      await controller.pause();
      await controller.dispose();
    }

    _videoController = null;
    _isVideoInitialized = false;
    _hasVideoError = false;
  }

  Future<void> _initVideoIfNeeded() async {
    if (_currentStep >= widget.steps.length) return;

    final step = widget.steps[_currentStep];
    final mediaUrl = (step['mediaUrl'] ?? '') as String;
    final mediaType = (step['mediaType'] ?? 'image') as String;

    if (mediaType != 'video' || mediaUrl.isEmpty) {
      return;
    }

    setState(() {
      _isVideoInitialized = false;
      _hasVideoError = false;
    });

    final controller = CachedVideoPlayerPlusController.networkUrl(
      Uri.parse(mediaUrl),
      invalidateCacheIfOlderThan: const Duration(days: 7),
    );

    _videoController = controller;

    try {
      await controller.initialize();

      if (!mounted || _videoController != controller) return;

      await controller.setVolume(0.0);
      await controller.setLooping(true);
      await controller.setPlaybackSpeed(_playbackSpeed);
      await controller.play();

      if (!mounted) return;

      setState(() {
        _isVideoInitialized = true;
        _hasVideoError = false;
      });
    } catch (e) {
      if (!mounted || _videoController != controller) return;

      setState(() {
        _hasVideoError = true;
        _isVideoInitialized = false;
      });
    }
  }

  Future<void> _goToStep(int index) async {
    if (index >= 0 && index < widget.steps.length && index != _currentStep) {
      await _disposeVideoController();

      if (!mounted) return;

      setState(() {
        _currentStep = index;
      });

      await _initVideoIfNeeded();
    }
  }

  Future<void> _nextStep() async {
    if (_currentStep < widget.steps.length - 1) {
      await _goToStep(_currentStep + 1);
    }
  }

  Future<void> _prevStep() async {
    if (_currentStep > 0) {
      await _goToStep(_currentStep - 1);
    }
  }

  Future<void> _loadCompletionState() async {
    final userId = context.read<AuthProvider>().firebaseUser?.uid;
    if (userId == null) return;

    try {
      final isCompleted = await _firestoreService.isLessonCompleted(
        userId,
        widget.courseId,
        widget.lessonId,
        sectionId: widget.sectionId,
      );

      if (!mounted) return;

      setState(() {
        _lessonCompleted = isCompleted;
      });
    } catch (_) {
      // Keep the screen usable even if progress check fails.
    }
  }

  Future<void> _markAsCompleted() async {
    final loc = AppLocalizations.of(context)!;
    final userId = context.read<AuthProvider>().firebaseUser?.uid;

    if (userId == null) {
      setState(() {
        _lessonCompleted = true;
      });
      return;
    }

    try {
      await _firestoreService.updateLessonProgress(
        userId,
        widget.courseId,
        widget.lessonId,
        widget.sectionId,
      );

      if (!mounted) return;

      setState(() {
        _lessonCompleted = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.lessonCompleted),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.errorOccurred),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _startQuiz() {
    _videoController?.pause();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          courseId: widget.courseId,
          sectionId: widget.sectionId,
          lessonId: widget.lessonId,
          lessonTitle: widget.lessonTitle,
        ),
      ),
    );
  }

  Future<void> _updatePlaybackSpeed(double value) async {
    final nextSpeed = double.parse(value.toStringAsFixed(1));

    setState(() {
      _playbackSpeed = nextSpeed;
    });

    if (_isVideoInitialized && _videoController != null) {
      await _videoController!.setPlaybackSpeed(nextSpeed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final langCode = context.watch<LanguageProvider>().currentLanguageCode;
    final totalSteps = widget.steps.length;

    if (totalSteps == 0) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.lessonTitle),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
        ),
        body: Center(
          child: Text(loc.noData),
        ),
      );
    }

    final step = widget.steps[_currentStep];
    final mediaUrl = (step['mediaUrl'] ?? '') as String;
    final mediaType = (step['mediaType'] ?? 'image') as String;
    final descMap = step['description'] as Map<String, dynamic>? ?? {};
    final description = (descMap[langCode] ?? descMap['ru'] ?? '') as String;
    final progress = (_currentStep + 1) / totalSteps;
    final isLastStep = _currentStep == totalSteps - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.lessonTitle,
          style: const TextStyle(fontSize: 18),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Прогресс-бар сверху
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: AppColors.primary.withOpacity(0.05),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${loc.step} ${_currentStep + 1} / $totalSteps',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${(progress * 100).round()}%',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: widget.levelColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(widget.levelColor),
                  ),
                ),
              ],
            ),
          ),

          // Контент шага
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildMedia(mediaUrl, mediaType),
                  if (mediaType == 'video' && mediaUrl.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildPlaybackSpeedControl(langCode),
                  ],
                  const SizedBox(height: 20),
                  if (description.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.levelColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: widget.levelColor.withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        description,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              height: 1.5,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Нижняя панель с кнопками
          _buildBottomBar(loc, isLastStep),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AppLocalizations loc, bool isLastStep) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Навигация (Назад / Далее или Завершить)
          Row(
            children: [
              if (_currentStep > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _prevStep,
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    label: Text(loc.previous),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                )
              else
                const Expanded(child: SizedBox()),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: isLastStep
                    ? ElevatedButton.icon(
                        onPressed: _lessonCompleted ? null : _markAsCompleted,
                        icon: Icon(
                          _lessonCompleted
                              ? Icons.check_circle
                              : Icons.check_circle_outline,
                          size: 20,
                        ),
                        label: Text(
                          _lessonCompleted
                              ? loc.completed
                              : loc.markAsCompleted,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _lessonCompleted
                              ? Colors.grey.shade300
                              : AppColors.success,
                          foregroundColor: _lessonCompleted
                              ? Colors.grey.shade600
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: _nextStep,
                        icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                        label: Text(loc.next),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
              ),
            ],
          ),

          // Кнопка "Начать тест" — появляется после завершения урока
          if (_lessonCompleted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _startQuiz,
                icon: const Icon(Icons.quiz_outlined, size: 22),
                label: Text(
                  loc.startQuiz,
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedia(String mediaUrl, String mediaType) {
    if (mediaUrl.isEmpty) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: widget.levelColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.levelColor.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mediaType == 'video'
                  ? Icons.videocam_outlined
                  : Icons.image_outlined,
              size: 56,
              color: widget.levelColor.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              mediaType == 'video'
                  ? 'Видео будет добавлено'
                  : 'Изображение будет добавлено',
              style: TextStyle(
                color: widget.levelColor.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (mediaType == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          mediaUrl,
          height: 250,
          width: double.infinity,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey.shade100,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    if (_hasVideoError) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              'Не удалось загрузить видео',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (!_isVideoInitialized || _videoController == null) {
      return Container(
        height: 250,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final controller = _videoController!;
    final size = controller.value.size;

    double aspectRatio;

    if (size.width > 0 && size.height > 0) {
      final isPortrait = size.height > size.width;

      if (isPortrait) {
        aspectRatio = 9 / 16;
      } else {
        aspectRatio = size.width / size.height;
      }
    } else {
      aspectRatio = 9 / 16;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        color: Colors.black,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: CachedVideoPlayerPlus(controller),
        ),
      ),
    );
  }

  Widget _buildPlaybackSpeedControl(String langCode) {
    final isEnabled = _isVideoInitialized && !_hasVideoError;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      decoration: BoxDecoration(
        color: widget.levelColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: widget.levelColor.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.slow_motion_video_rounded,
                color: isEnabled
                    ? widget.levelColor
                    : AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _speedLabel(langCode),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isEnabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                ),
              ),
              Text(
                _formatSpeed(_playbackSpeed),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isEnabled
                          ? widget.levelColor
                          : AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          Slider(
            value: _playbackSpeed,
            min: 0.5,
            max: 1.0,
            divisions: 5,
            label: _formatSpeed(_playbackSpeed),
            activeColor: widget.levelColor,
            inactiveColor: widget.levelColor.withValues(alpha: 0.18),
            onChanged: isEnabled ? _updatePlaybackSpeed : null,
          ),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('0.5x'),
              Text('1x'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatSpeed(double speed) {
    final fixed = speed.toStringAsFixed(1);
    return fixed.endsWith('.0') ? '${speed.toInt()}x' : '${fixed}x';
  }

  String _speedLabel(String langCode) {
    switch (langCode) {
      case 'kk':
        return 'Видео жылдамдығы';
      case 'en':
        return 'Video speed';
      case 'ru':
      default:
        return 'Скорость видео';
    }
  }
}
