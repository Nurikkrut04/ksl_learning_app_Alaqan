import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ksl_learning_app/core/localization/l10n/app_localizations.dart';

import '../../providers/language_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../services/firestore_service.dart';
import 'course_detail_screen.dart';

class LevelSelectionScreen extends StatefulWidget {
  final String topicId;
  final String topicTitle;
  final Color topicColor;
  final IconData topicIcon;

  const LevelSelectionScreen({
    super.key,
    required this.topicId,
    required this.topicTitle,
    required this.topicColor,
    required this.topicIcon,
  });

  @override
  State<LevelSelectionScreen> createState() => _LevelSelectionScreenState();
}

class _LevelSelectionScreenState extends State<LevelSelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  List<Map<String, dynamic>>? _levels;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  Future<void> _loadLevels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final levels = await _firestoreService.getLevels();
      if (!mounted) return;
      setState(() {
        _levels = levels;
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          _buildHeader(l10n),
          Expanded(
            child: _buildBody(l10n, langCode),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.topicColor,
            widget.topicColor.withOpacity(0.76),
          ],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: _TopicHeaderPattern(
                topicId: widget.topicId,
                color: Colors.white,
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      widget.topicIcon,
                      size: 46,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.topicTitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.difficulty,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.86),
                        ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
        ],
      ),
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
              onPressed: _loadLevels,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final levels = _levels ?? [];
    if (levels.isEmpty) {
      return Center(child: Text(l10n.noData));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: levels.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final level = levels[index];
        final levelId = level['id'] as String;
        final titleMap = level['title'] as Map<String, dynamic>? ?? {};
        final title = (titleMap[langCode] ?? titleMap['ru'] ?? '') as String;

        return _LevelButton(
          title: title,
          color: _getLevelColor(levelId),
          icon: _getLevelIcon(levelId),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CourseDetailScreen(
                  topicId: widget.topicId,
                  topicTitle: widget.topicTitle,
                  levelId: levelId,
                  levelTitle: title,
                ),
              ),
            );
          },
        );
      },
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

  IconData _getLevelIcon(String levelId) {
    switch (levelId) {
      case 'beginner':
        return Icons.star_outline_rounded;
      case 'intermediate':
        return Icons.star_half_rounded;
      case 'advanced':
        return Icons.star_rounded;
      default:
        return Icons.star_outline_rounded;
    }
  }
}

class _TopicHeaderPattern extends StatelessWidget {
  final String topicId;
  final Color color;

  const _TopicHeaderPattern({
    required this.topicId,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final icons = _getPatternIcons(topicId);

    return Stack(
      children: [
        _PatternIcon(
          icon: icons[0],
          top: 38,
          left: 28,
          size: 28,
          angle: -0.18,
          color: color,
        ),
        _PatternIcon(
          icon: icons[1],
          top: 54,
          right: 26,
          size: 30,
          angle: 0.22,
          color: color,
        ),
        _PatternIcon(
          icon: icons[2],
          top: 116,
          left: -4,
          size: 52,
          angle: -0.28,
          color: color,
        ),
        _PatternIcon(
          icon: icons[3],
          top: 122,
          right: -6,
          size: 52,
          angle: 0.24,
          color: color,
        ),
        _PatternIcon(
          icon: icons[4],
          bottom: 34,
          left: 30,
          size: 40,
          angle: -0.14,
          color: color,
        ),
        _PatternIcon(
          icon: icons[5],
          bottom: 28,
          right: 34,
          size: 38,
          angle: 0.16,
          color: color,
        ),
      ],
    );
  }

  List<IconData> _getPatternIcons(String topicId) {
    switch (topicId) {
      case 'communication':
        return const [
          Icons.chat_bubble_outline_rounded,
          Icons.favorite_border_rounded,
          Icons.pan_tool_alt_rounded,
          Icons.groups_rounded,
          Icons.front_hand_rounded,
          Icons.volunteer_activism_rounded,
        ];
      case 'family':
        return const [
          Icons.home_rounded,
          Icons.favorite_rounded,
          Icons.family_restroom_rounded,
          Icons.people_alt_rounded,
          Icons.child_care_rounded,
          Icons.groups_rounded,
        ];
      case 'food':
        return const [
          Icons.local_cafe_rounded,
          Icons.emoji_food_beverage_rounded,
          Icons.restaurant_rounded,
          Icons.lunch_dining_rounded,
          Icons.bakery_dining_rounded,
          Icons.dinner_dining_rounded,
        ];
      case 'culture':
        return const [
          Icons.music_note_rounded,
          Icons.auto_awesome_rounded,
          Icons.account_balance_rounded,
          Icons.celebration_rounded,
          Icons.theater_comedy_rounded,
          Icons.temple_buddhist_rounded,
        ];
      case 'nature':
        return const [
          Icons.wb_sunny_rounded,
          Icons.water_drop_rounded,
          Icons.park_rounded,
          Icons.eco_rounded,
          Icons.air_rounded,
          Icons.spa_rounded,
        ];
      case 'professions':
        return const [
          Icons.school_rounded,
          Icons.medical_services_rounded,
          Icons.work_rounded,
          Icons.engineering_rounded,
          Icons.business_center_rounded,
          Icons.menu_book_rounded,
        ];
      default:
        return const [
          Icons.circle_outlined,
          Icons.circle_outlined,
          Icons.circle_outlined,
          Icons.circle_outlined,
          Icons.circle_outlined,
          Icons.circle_outlined,
        ];
    }
  }
}

class _PatternIcon extends StatelessWidget {
  final IconData icon;
  final double? top;
  final double? left;
  final double? right;
  final double? bottom;
  final double size;
  final double angle;
  final Color color;

  const _PatternIcon({
    required this.icon,
    this.top,
    this.left,
    this.right,
    this.bottom,
    required this.size,
    required this.angle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Transform.rotate(
        angle: angle,
        child: Icon(
          icon,
          size: size,
          color: color.withOpacity(0.08),
        ),
      ),
    );
  }
}

class _LevelButton extends StatelessWidget {
  final String title;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _LevelButton({
    required this.title,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      shadowColor: color.withOpacity(0.18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
