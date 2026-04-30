import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:si2_p1_mobile/shared/utils/responsive.dart';

class LoadingDialog {
  static void show(
    BuildContext context, {
    String title = 'Procesando',
    String? subtitle,
    bool barrierDismissible = false,
  }) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black54,
      builder: (_) => PopScope(
        canPop: barrierDismissible,
        child: Center(
          child: _LoadingContent(title: title, subtitle: subtitle),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

class _LoadingContent extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _LoadingContent({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final res = context.responsive;
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(res.spacing(28)),
        margin: EdgeInsets.symmetric(horizontal: res.spacing(48)),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(res.radius(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(height: res.spacing(16)),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: res.fontSize(16),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: res.spacing(6)),
              Text(
                subtitle!,
                style: GoogleFonts.inter(
                  fontSize: res.fontSize(13),
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }
}
