import 'dart:ui';
import 'package:flutter/material.dart';

class TopicExpandRoute<T> extends PageRouteBuilder<T> {
  final Rect sourceRect;
  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget page;

  TopicExpandRoute({
    required this.sourceRect,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.page,
  }) : super(
          opaque: false,
          barrierColor: Colors.transparent,
          transitionDuration: const Duration(milliseconds: 560),
          reverseTransitionDuration: const Duration(milliseconds: 420),
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final screenSize = MediaQuery.of(context).size;

            final curved = CurvedAnimation(
              parent: animation,
              curve: const Cubic(0.22, 1.0, 0.36, 1.0),
              reverseCurve: Curves.easeInCubic,
            );

            final t = curved.value;

            final currentRect =
                Rect.lerp(sourceRect, Offset.zero & screenSize, t)!;

            final currentRadius = lerpDouble(16, 0, t)!;

            final shellOpacity = 1.0 -
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.18, 0.62, curve: Curves.easeOut),
                ).value;

            final pageOpacity = CurvedAnimation(
              parent: animation,
              curve: const Interval(0.58, 1.0, curve: Curves.easeOutCubic),
            ).value;

            final pageScale = Tween<double>(
              begin: 1.015,
              end: 1.0,
            ).transform(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.58, 1.0, curve: Curves.easeOutCubic),
              ).value,
            );

            final scrimOpacity = Tween<double>(
              begin: 0.0,
              end: 0.035,
            ).transform(
              CurvedAnimation(
                parent: animation,
                curve: const Interval(0.0, 0.55, curve: Curves.easeOut),
              ).value,
            );

            return Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: ColoredBox(
                      color: Colors.black.withOpacity(scrimOpacity),
                    ),
                  ),
                ),
                Positioned(
                  left: currentRect.left,
                  top: currentRect.top,
                  width: currentRect.width,
                  height: currentRect.height,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(currentRadius),
                    child: Material(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Opacity(
                            opacity: shellOpacity,
                            child: _CardShellPreview(
                              title: title,
                              icon: icon,
                              accentColor: accentColor,
                            ),
                          ),
                          Transform.scale(
                            scale: pageScale,
                            child: Opacity(
                              opacity: pageOpacity,
                              child: child,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
}

class _CardShellPreview extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;

  const _CardShellPreview({
    required this.title,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 36,
              color: accentColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}
