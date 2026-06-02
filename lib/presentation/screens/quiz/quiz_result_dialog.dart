import 'package:flutter/material.dart';
import 'package:ksl_learning_app/core/localization/l10n/app_localizations.dart';

class QuizResultDialog extends StatelessWidget {
  final int correctCount;
  final int totalCount;
  final int percent;
  final VoidCallback onOk;

  const QuizResultDialog({
    super.key,
    required this.correctCount,
    required this.totalCount,
    required this.percent,
    required this.onOk,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final resultStyle = _resultStyle(percent);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: resultStyle.color.withOpacity(0.12),
              child: Icon(
                resultStyle.icon,
                size: 44,
                color: resultStyle.color,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${loc.correctAnswers}: $correctCount / $totalCount',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              loc.percentage(percent),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: resultStyle.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 120,
              child: ElevatedButton(
                onPressed: onOk,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                  foregroundColor: theme.colorScheme.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  loc.ok,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _QuizResultStyle _resultStyle(int percent) {
    if (percent == 100) {
      return const _QuizResultStyle(
        icon: Icons.celebration_rounded,
        color: Colors.green,
      );
    }

    if (percent >= 50) {
      return const _QuizResultStyle(
        icon: Icons.thumb_up_alt_rounded,
        color: Colors.orange,
      );
    }

    return const _QuizResultStyle(
      icon: Icons.sentiment_neutral_rounded,
      color: Colors.red,
    );
  }
}

class _QuizResultStyle {
  final IconData icon;
  final Color color;

  const _QuizResultStyle({
    required this.icon,
    required this.color,
  });
}
