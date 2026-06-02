import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ksl_learning_app/core/localization/l10n/app_localizations.dart';

import '../../../core/theme/colors.dart';
import '../../../services/firestore_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/common/animated_bottom_nav_bar.dart';
import '../courses/courses_catalog_screen.dart';
import '../profile/profile_screen.dart';
import 'level_selection_screen.dart';
import 'topic_expand_route.dart';

class HomeScreen extends StatefulWidget {
  final int initialIndex;

  const HomeScreen({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const int _plansPriceKzt = 5000;
  static const String _professionsTopicId = 'professions';

  final FirestoreService _firestoreService = FirestoreService();

  late int _currentIndex;
  List<Map<String, dynamic>>? _cachedTopics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 3) as int;
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final topics = await _firestoreService.getTopics();
      if (!mounted) return;

      setState(() {
        _cachedTopics = topics;
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

  Rect? _getRectFromKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;

    final renderObject = ctx.findRenderObject();
    if (renderObject is! RenderBox) return null;

    final offset = renderObject.localToGlobal(Offset.zero);
    return offset & renderObject.size;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      body: _buildBody(l10n, authProvider),
      bottomNavigationBar: AnimatedBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        activeColor: AppColors.primary,
        inactiveColor: AppColors.textHint,
        items: [
          NavBarItem(
            icon: Icons.grid_view_rounded,
            label: l10n.home,
          ),
          NavBarItem(
            icon: Icons.menu_book_rounded,
            label: l10n.courses,
          ),
          NavBarItem(
            icon: Icons.star_rounded,
            label: l10n.plans,
          ),
          NavBarItem(
            icon: Icons.person_outline_rounded,
            label: l10n.profile,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n, AuthProvider authProvider) {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab(l10n, authProvider);
      case 1:
        return const CoursesCatalogScreen();
      case 2:
        return _buildPlansTab(authProvider);
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeTab(l10n, authProvider);
    }
  }

  Widget _buildHomeTab(AppLocalizations l10n, AuthProvider authProvider) {
    final langCode = context.watch<LanguageProvider>().currentLanguageCode;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              l10n.learningTopics,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _homeDescription(context),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _buildTopicsGrid(
                l10n: l10n,
                langCode: langCode,
                authProvider: authProvider,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicsGrid({
    required AppLocalizations l10n,
    required String langCode,
    required AuthProvider authProvider,
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
            Text(
              l10n.errorOccurred,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadTopics,
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    final topics = _cachedTopics ?? [];
    if (topics.isEmpty) {
      return Center(child: Text(l10n.noData));
    }

    return GridView.builder(
      itemCount: topics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final topic = topics[index];
        final topicId = topic['id'] as String;
        final titleMap = topic['title'] as Map<String, dynamic>? ?? {};
        final title = (titleMap[langCode] ?? titleMap['ru'] ?? '') as String;
        final topicColor = _getTopicColor(topicId);
        final topicIcon = _getTopicIcon(topicId);
        final isLocked = _requiresProfessionsAccess(topicId) &&
            !authProvider.hasProfessionsAccess;

        final cardKey = GlobalKey();

        return _TopicCard(
          cardKey: cardKey,
          title: title,
          icon: topicIcon,
          color: topicColor,
          isLocked: isLocked,
          lockPriceLabel: _priceLabel(context),
          onTap: () {
            if (isLocked) {
              _showProfessionsLockedDialog();
              return;
            }

            final rect = _getRectFromKey(cardKey);
            if (rect == null) return;

            Navigator.of(context).push(
              TopicExpandRoute(
                sourceRect: rect,
                title: title,
                icon: topicIcon,
                accentColor: topicColor,
                page: LevelSelectionScreen(
                  topicId: topicId,
                  topicTitle: title,
                  topicColor: topicColor,
                  topicIcon: topicIcon,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPlansTab(AuthProvider authProvider) {
    final theme = Theme.of(context);
    final hasAccess = authProvider.hasProfessionsAccess;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.secondaryGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: AppColors.secondary.withOpacity(0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _plansTitle(context),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _plansSubtitle(context),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withOpacity(0.92),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            AppColors.categoryProfessions.withOpacity(0.14),
                        child: const Icon(
                          Icons.work_rounded,
                          color: AppColors.categoryProfessions,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _professionsPlanName(context),
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              hasAccess
                                  ? _subscriptionActiveText(context)
                                  : _oneTimeAccessText(context),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _priceLabel(context),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.categoryProfessions,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ...[
                    _planFeatureText(
                      context,
                      feature: 'full_professions_topic',
                    ),
                    _planFeatureText(
                      context,
                      feature: 'all_levels',
                    ),
                    _planFeatureText(
                      context,
                      feature: 'unlock_catalog',
                    ),
                  ].map(
                    (text) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            size: 20,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              text,
                              style: theme.textTheme.bodyLarge,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _plansNotice(context),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (hasAccess)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _currentIndex = 0;
                          });
                        },
                        icon: const Icon(Icons.school_rounded),
                        label: Text(_goToLearningText(context)),
                      ),
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: authProvider.isLoading
                            ? null
                            : () => _handleProfessionsPurchase(authProvider),
                        icon: Icon(
                          authProvider.isLoading
                              ? Icons.hourglass_top_rounded
                              : Icons.credit_card_rounded,
                        ),
                        label: Text(
                          authProvider.isLoading
                              ? _savingText(context)
                              : _buyForText(context, _plansPriceKzt),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleProfessionsPurchase(AuthProvider authProvider) async {
    if (authProvider.hasProfessionsAccess) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_alreadyUnlockedSnack(context)),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(_confirmPurchaseTitle(context)),
            content: Text(_confirmPurchaseBody(context, _plansPriceKzt)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(_cancelText(context)),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(_confirmPaymentText(context)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final success = await authProvider.purchaseProfessionsAccess();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? _purchaseSuccessText(context)
              : (authProvider.errorMessage ?? _purchaseFailedText(context)),
        ),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ),
    );
  }

  Future<void> _showProfessionsLockedDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_lockedTitle(context)),
        content: Text(_lockedBody(context, _plansPriceKzt)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(_closeText(context)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                _currentIndex = 2;
              });
            },
            child: Text(_openPlansText(context)),
          ),
        ],
      ),
    );
  }

  bool _requiresProfessionsAccess(String topicId) {
    return topicId == _professionsTopicId;
  }

  String _priceLabel(BuildContext context) {
    return _text(
      context,
      kk: '$_plansPriceKzt тг',
      ru: '$_plansPriceKzt тг',
      en: '$_plansPriceKzt KZT',
    );
  }

  String _homeDescription(BuildContext context) {
    return _text(
      context,
      kk: 'Оқу тақырыбын таңдаңыз.',
      ru: 'Выберите тему обучения.',
      en: 'Choose a learning topic.',
    );
  }

  String _plansTitle(BuildContext context) {
    return _text(
      context,
      kk: 'Жазылым және арнайы қолжетімділік',
      ru: 'Подписка и специальный доступ',
      en: 'Plans and premium access',
    );
  }

  String _plansSubtitle(BuildContext context) {
    return _text(
      context,
      kk:
          'Бұл бөлімде қосымша контентке қолжетімділік ашылады. Қазіргі ақылы жоспар Professions курсына арналған.',
      ru:
          'В этом разделе открывается дополнительный доступ. Текущий платный план предназначен для курса Professions.',
      en:
          'This section unlocks additional access. The current paid plan is for the Professions course.',
    );
  }

  String _professionsPlanName(BuildContext context) {
    return _text(
      context,
      kk: 'Professions курсына қолжетімділік',
      ru: 'Доступ к курсу Professions',
      en: 'Professions course access',
    );
  }

  String _subscriptionActiveText(BuildContext context) {
    return _text(
      context,
      kk: 'Қолжетімділік белсенді',
      ru: 'Доступ уже активен',
      en: 'Access already active',
    );
  }

  String _oneTimeAccessText(BuildContext context) {
    return _text(
      context,
      kk: 'Бір реттік сатып алу',
      ru: 'Разовая покупка доступа',
      en: 'One-time access purchase',
    );
  }

  String _planFeatureText(BuildContext context, {required String feature}) {
    switch (feature) {
      case 'full_professions_topic':
        return _text(
          context,
          kk: 'Professions тақырыбы толық ашылады',
          ru: 'Открывается полный доступ к теме Professions',
          en: 'Unlocks the full Professions topic',
        );
      case 'all_levels':
        return _text(
          context,
          kk: 'Beginner, Intermediate және Advanced деңгейлері ашылады',
          ru: 'Открываются уровни Beginner, Intermediate и Advanced',
          en: 'Access to Beginner, Intermediate, and Advanced levels',
        );
      case 'unlock_catalog':
      default:
        return _text(
          context,
          kk: 'Блокировка басты бетте және курстар каталогында алынады',
          ru: 'Снимается блокировка на главной странице и в каталоге курсов',
          en: 'Unlocks the topic on the home screen and in the course catalog',
        );
    }
  }

  String _plansNotice(BuildContext context) {
    return _text(
      context,
      kk:
          'Қазір төлем ағыны демонстрациялық режимде жұмыс істейді: растаудан кейін қолжетімділік пайдаланушы профиліне сақталады.',
      ru:
          'Сейчас сценарий оплаты работает в демонстрационном режиме: после подтверждения доступ сохраняется в профиле пользователя.',
      en:
          'The payment flow currently works in demo mode: after confirmation, access is saved to the user profile.',
    );
  }

  String _savingText(BuildContext context) {
    return _text(
      context,
      kk: 'Өңделуде...',
      ru: 'Обработка...',
      en: 'Processing...',
    );
  }

  String _buyForText(BuildContext context, int price) {
    return _text(
      context,
      kk: '$price тг үшін ашу',
      ru: 'Открыть за $price тг',
      en: 'Unlock for $price KZT',
    );
  }

  String _goToLearningText(BuildContext context) {
    return _text(
      context,
      kk: 'Оқуға оралу',
      ru: 'Перейти к обучению',
      en: 'Go to learning',
    );
  }

  String _alreadyUnlockedSnack(BuildContext context) {
    return _text(
      context,
      kk: 'Professions курсы бұрыннан ашық.',
      ru: 'Курс Professions уже открыт.',
      en: 'The Professions course is already unlocked.',
    );
  }

  String _confirmPurchaseTitle(BuildContext context) {
    return _text(
      context,
      kk: 'Сатып алуды растау',
      ru: 'Подтверждение покупки',
      en: 'Confirm purchase',
    );
  }

  String _confirmPurchaseBody(BuildContext context, int price) {
    return _text(
      context,
      kk:
          'Сіз Professions курсына қолжетімділікті $price тг бағасымен ашасыз. Жалғастырасыз ба?',
      ru:
          'Вы открываете доступ к курсу Professions за $price тг. Продолжить?',
      en:
          'You are unlocking access to the Professions course for $price KZT. Continue?',
    );
  }

  String _cancelText(BuildContext context) {
    return _text(
      context,
      kk: 'Бас тарту',
      ru: 'Отмена',
      en: 'Cancel',
    );
  }

  String _confirmPaymentText(BuildContext context) {
    return _text(
      context,
      kk: 'Төлеу',
      ru: 'Оплатить',
      en: 'Pay now',
    );
  }

  String _purchaseSuccessText(BuildContext context) {
    return _text(
      context,
      kk: 'Төлем сәтті өтті. Professions курсы ашылды.',
      ru: 'Оплата прошла успешно. Курс Professions открыт.',
      en: 'Payment successful. The Professions course is now unlocked.',
    );
  }

  String _purchaseFailedText(BuildContext context) {
    return _text(
      context,
      kk: 'Қолжетімділікті ашу мүмкін болмады.',
      ru: 'Не удалось открыть доступ.',
      en: 'Could not unlock access.',
    );
  }

  String _lockedTitle(BuildContext context) {
    return _text(
      context,
      kk: 'Тақырып бұғатталған',
      ru: 'Тема заблокирована',
      en: 'Topic locked',
    );
  }

  String _lockedBody(BuildContext context, int price) {
    return _text(
      context,
      kk:
          'Professions тақырыбы арнайы жоспар арқылы ашылады. Құны: $price тг.',
      ru:
          'Тема Professions открывается через специальный план. Стоимость: $price тг.',
      en:
          'The Professions topic unlocks through a special plan. Price: $price KZT.',
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

  String _openPlansText(BuildContext context) {
    return _text(
      context,
      kk: 'Plans ашу',
      ru: 'Открыть Plans',
      en: 'Open Plans',
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

  IconData _getTopicIcon(String topicId) {
    switch (topicId) {
      case 'communication':
        return Icons.people_alt_rounded;
      case 'family':
        return Icons.family_restroom_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'culture':
        return Icons.account_balance_rounded;
      case 'nature':
        return Icons.park_rounded;
      case 'professions':
        return Icons.work_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  Color _getTopicColor(String topicId) {
    switch (topicId) {
      case 'communication':
        return AppColors.categoryCommunication;
      case 'family':
        return AppColors.categoryFamily;
      case 'food':
        return AppColors.categoryFood;
      case 'culture':
        return AppColors.categoryCulture;
      case 'nature':
        return AppColors.categoryNature;
      case 'professions':
        return AppColors.categoryProfessions;
      default:
        return AppColors.primary;
    }
  }
}

class _TopicCard extends StatelessWidget {
  final GlobalKey cardKey;
  final String title;
  final IconData icon;
  final Color color;
  final bool isLocked;
  final String lockPriceLabel;
  final VoidCallback onTap;

  const _TopicCard({
    required this.cardKey,
    required this.title,
    required this.icon,
    required this.color,
    required this.isLocked,
    required this.lockPriceLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      key: cardKey,
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 36,
                        color: color,
                      ),
                    ),
                    if (isLocked)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.surface,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isLocked) ...[
                  const SizedBox(height: 8),
                  Text(
                    lockPriceLabel,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: AppColors.secondaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
