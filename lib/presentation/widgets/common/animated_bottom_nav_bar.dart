import 'package:flutter/material.dart';

/// Data class for a single navigation bar item.
class NavBarItem {
  final IconData icon;
  final String label;

  const NavBarItem({
    required this.icon,
    required this.label,
  });
}

/// Animated Bottom Navigation Bar for Qoldas KSL Learning App.
///
/// Features:
/// - Only icons are shown by default (inactive tabs have no text)
/// - When a tab becomes active, its label fades in + slides up
/// - Active icon bounces & wiggles on selection
/// - Active tab gets a subtle tinted background pill
/// - Fully supports localized labels (KZ, RU, EN)
///
/// Place this file at:
///   lib/presentation/widgets/common/animated_bottom_nav_bar.dart
///
/// Usage:
/// ```dart
/// AnimatedBottomNavBar(
///   currentIndex: _currentIndex,
///   onTap: (i) => setState(() => _currentIndex = i),
///   items: [
///     NavBarItem(icon: Icons.home_rounded, label: localizations.home),
///     NavBarItem(icon: Icons.menu_book_rounded, label: localizations.courses),
///     NavBarItem(icon: Icons.star_rounded, label: localizations.plans),
///     NavBarItem(icon: Icons.person_rounded, label: localizations.profile),
///   ],
/// )
/// ```
class AnimatedBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<NavBarItem> items;
  final Color? activeColor;
  final Color? inactiveColor;
  final Color? backgroundColor;

  const AnimatedBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.activeColor,
    this.inactiveColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveActiveColor = activeColor ?? theme.primaryColor;
    final effectiveInactiveColor = inactiveColor ?? Colors.grey.shade400;
    final effectiveBgColor = backgroundColor ?? theme.scaffoldBackgroundColor;

    return Container(
      decoration: BoxDecoration(
        color: effectiveBgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              return Expanded(
                child: _NavBarItemWidget(
                  item: items[index],
                  isActive: index == currentIndex,
                  activeColor: effectiveActiveColor,
                  inactiveColor: effectiveInactiveColor,
                  onTap: () => onTap(index),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Individual tab item with bounce + wiggle + label animations
// ─────────────────────────────────────────────────────────────

class _NavBarItemWidget extends StatefulWidget {
  final NavBarItem item;
  final bool isActive;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavBarItemWidget({
    required this.item,
    required this.isActive,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  State<_NavBarItemWidget> createState() => _NavBarItemWidgetState();
}

class _NavBarItemWidgetState extends State<_NavBarItemWidget>
    with TickerProviderStateMixin {
  // Bounce animation controller (scale effect)
  late final AnimationController _bounceCtrl;
  late final Animation<double> _bounceAnim;

  // Wiggle animation controller (rotation effect)
  late final AnimationController _wiggleCtrl;
  late final Animation<double> _wiggleAnim;

  @override
  void initState() {
    super.initState();

    // ── Bounce: 1.0 → 1.3 → 0.85 → 1.05 → 1.0 ──
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _bounceAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 0.85), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.05), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 25),
    ]).animate(CurvedAnimation(
      parent: _bounceCtrl,
      curve: Curves.easeOut,
    ));

    // ── Wiggle: slight left-right rotation ──
    _wiggleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _wiggleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.1), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.08), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.05), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: -0.02), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -0.02, end: 0.0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _wiggleCtrl,
      curve: Curves.easeOut,
    ));
  }

  @override
  void didUpdateWidget(covariant _NavBarItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Trigger animations when this tab becomes newly active
    if (widget.isActive && !oldWidget.isActive) {
      _bounceCtrl.forward(from: 0);
      _wiggleCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _wiggleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isActive ? widget.activeColor : widget.inactiveColor;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Animated Icon with bounce + wiggle ──
            ListenableBuilder(
              listenable: Listenable.merge([_bounceCtrl, _wiggleCtrl]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _bounceAnim.value,
                  child: Transform.rotate(
                    angle: _wiggleAnim.value,
                    child: child,
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(widget.isActive ? 8 : 6),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? widget.activeColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  widget.item.icon,
                  color: color,
                  size: widget.isActive ? 26 : 24,
                ),
              ),
            ),

            const SizedBox(height: 2),

            // ── Label: fade + slide up, visible only when active ──
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.4),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: widget.isActive
                  ? Text(
                      widget.item.label,
                      key: ValueKey('label_${widget.item.label}'),
                      style: TextStyle(
                        color: widget.activeColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  : const SizedBox(
                      key: ValueKey('empty_label'),
                      height: 13.2, // preserves layout so nothing jumps
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
