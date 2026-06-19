import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:si2_p1_mobile/shared/utils/responsive.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsets? margin;
  final EdgeInsets padding;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blurStrength;
  final List<BoxShadow>? shadows;
  final bool animated;
  final Duration animationDuration;
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
    this.borderColor,
    this.blurStrength = 10,
    this.shadows,
    this.animated = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bool disableAnimations = MediaQuery.of(context).disableAnimations;

    final modernShadows = shadows ??
        [
          if (isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            )
          else
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
        ];

    final modernBorder = Border.all(
      color: borderColor ??
          (isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.06)),
      width: 1,
    );

    Widget card = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: modernShadows,
        border: modernBorder,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(
            sigmaX: blurStrength,
            sigmaY: blurStrength,
          ),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor ??
                  (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.white.withOpacity(0.8)),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      card = GestureDetector(
        onTap: onTap,
        child: disableAnimations
            ? card
            : card
                .animate(target: 1)
                .scale(
                  duration: 100.ms,
                  curve: Curves.easeOut,
                  begin: const Offset(1.0, 1.0),
                  end: const Offset(0.98, 0.98),
                ),
      );
    }

    final bool shouldAnimate = animated && !disableAnimations;
    if (shouldAnimate) {
      return card
          .animate(target: 1)
          .fadeIn(duration: 220.ms, curve: Curves.fastOutSlowIn)
          .slideY(
            duration: 220.ms,
            begin: 0.06,
            end: 0,
            curve: Curves.fastOutSlowIn,
          );
    }

    return card;
  }
}

class InfoGlassCard extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? accentColor;

  const InfoGlassCard({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final res = context.responsive;
    final theme = Theme.of(context);

    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          if (leading != null) ...[
            Container(
              padding: EdgeInsets.all(res.dp(0.9)),
              decoration: BoxDecoration(
                color: (accentColor ?? theme.colorScheme.primary)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(res.dp(0.9)),
              ),
              child: leading!,
            ),
            SizedBox(width: res.wp(3)),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: res.hp(0.2)),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[SizedBox(width: res.wp(2)), trailing!],
        ],
      ),
    );
  }
}
