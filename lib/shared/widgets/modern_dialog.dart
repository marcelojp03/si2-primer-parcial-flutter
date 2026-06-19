import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:si2_p1_mobile/shared/utils/responsive.dart';
import 'package:si2_p1_mobile/config/theme/app_theme.dart';

class DialogAction {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;
  final IconData? icon;

  const DialogAction({
    required this.label,
    required this.isPrimary,
    required this.onTap,
    this.icon,
  });
}

class ModernDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required String message,
    IconData? icon,
    Color? iconColor,
    List<DialogAction> actions = const [],
    bool barrierDismissible = true,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _ModernDialogWidget(
          title: title,
          message: message,
          icon: icon,
          iconColor: iconColor,
          actions: actions,
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1.0).animate(
              CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
                reverseCurve: Curves.easeInCubic,
              ),
            ),
            child: child,
          ),
        );
      },
    );
  }

  static Future<bool> confirm({
    required BuildContext context,
    required String title,
    required String message,
    IconData? icon,
    Color? iconColor,
    String confirmText = 'Confirmar',
    String cancelText = 'Cancelar',
    bool barrierDismissible = true,
  }) async {
    final result = await show<bool>(
      context: context,
      title: title,
      message: message,
      icon: icon,
      iconColor: iconColor,
      barrierDismissible: barrierDismissible,
      actions: [
        DialogAction(
          label: cancelText,
          isPrimary: false,
          onTap: () => Navigator.pop(context, false),
        ),
        DialogAction(
          label: confirmText,
          isPrimary: true,
          onTap: () => Navigator.pop(context, true),
        ),
      ],
    );
    return result ?? false;
  }
}

class _ModernDialogWidget extends StatefulWidget {
  final String title;
  final String message;
  final IconData? icon;
  final Color? iconColor;
  final List<DialogAction> actions;

  const _ModernDialogWidget({
    required this.title,
    required this.message,
    this.icon,
    this.iconColor,
    required this.actions,
  });

  @override
  State<_ModernDialogWidget> createState() => _ModernDialogWidgetState();
}

class _ModernDialogWidgetState extends State<_ModernDialogWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _iconScaleAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _iconScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _contentSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
          ),
        );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final res = context.responsive;
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(horizontal: res.wp(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(res.radius(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            constraints: BoxConstraints(maxWidth: res.wp(85)),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(res.radius(24)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1E1E1E).withOpacity(0.9),
                        const Color(0xFF2A2A2A).withOpacity(0.85),
                      ]
                    : [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.9),
                      ],
              ),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 32,
                  offset: const Offset(0, 16),
                  spreadRadius: -8,
                ),
              ],
            ),
            padding: EdgeInsets.all(res.wp(6)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  ScaleTransition(
                    scale: _iconScaleAnimation,
                    child: Container(
                      width: res.dp(6),
                      height: res.dp(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            (widget.iconColor ?? AppTheme.primaryColor)
                                .withOpacity(0.2),
                            (widget.iconColor ?? AppTheme.primaryColor)
                                .withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        size: res.dp(3.5),
                        color: widget.iconColor ?? AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  SizedBox(height: res.hp(2)),
                ],
                FadeTransition(
                  opacity: _contentFadeAnimation,
                  child: SlideTransition(
                    position: _contentSlideAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            fontSize: res.dp(2),
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: res.hp(1)),
                        Text(
                          widget.message,
                          style: GoogleFonts.inter(
                            fontSize: res.dp(1.5),
                            fontWeight: FontWeight.w400,
                            color: theme.colorScheme.onSurface
                                .withOpacity(0.7),
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: res.hp(3)),
                if (widget.actions.isNotEmpty)
                  FadeTransition(
                    opacity: _contentFadeAnimation,
                    child: Row(
                      children: widget.actions.map((action) {
                        final isLast = action == widget.actions.last;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: isLast ? 0 : res.wp(3),
                            ),
                            child: _ActionButton(action: action),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final DialogAction action;

  const _ActionButton({required this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final res = context.responsive;
    final isDark = theme.brightness == Brightness.dark;

    if (action.isPrimary) {
      return Material(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(res.radius(16)),
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(res.radius(16)),
          child: Container(
            height: res.hp(5.5),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (action.icon != null) ...[
                  Icon(action.icon, size: res.dp(2), color: Colors.white),
                  SizedBox(width: res.wp(2)),
                ],
                Text(
                  action.label,
                  style: GoogleFonts.inter(
                    fontSize: res.dp(1.55),
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Container(
        height: res.hp(5.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(res.radius(16)),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.2)
                : theme.colorScheme.outline.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: action.onTap,
            borderRadius: BorderRadius.circular(res.radius(16)),
            child: Container(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (action.icon != null) ...[
                    Icon(
                      action.icon,
                      size: res.dp(2),
                      color: theme.colorScheme.onSurface,
                    ),
                    SizedBox(width: res.wp(2)),
                  ],
                  Text(
                    action.label,
                    style: GoogleFonts.inter(
                      fontSize: res.dp(1.55),
                      fontWeight: FontWeight.w600,
                      color:
                          theme.colorScheme.onSurface.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
  }
}
