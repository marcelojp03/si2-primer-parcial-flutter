import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? margin;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? backgroundColor;
  final List<BoxShadow>? shadows;
  final bool animated;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.margin,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
    this.backgroundColor,
    this.shadows,
    this.animated = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final defaultShadows = [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.2)
            : Colors.black.withOpacity(0.07),
        blurRadius: isDark ? 8 : 16,
        offset: const Offset(0, 4),
        spreadRadius: 0,
      ),
    ];

    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ?? defaultShadows,
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.07)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: card,
      );
    }

    if (animated) {
      return card
          .animate()
          .fadeIn(duration: 250.ms)
          .slideY(begin: 0.04, end: 0, duration: 250.ms, curve: Curves.easeOut);
    }
    return card;
  }
}
