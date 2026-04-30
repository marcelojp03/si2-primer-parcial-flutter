import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum ToastType { success, error, warning, info }

enum ToastPosition { top, center, bottom }

class AppToast {
  static void show(
    BuildContext context, {
    required String message,
    ToastType type = ToastType.info,
    Duration duration = const Duration(milliseconds: 2500),
    ToastPosition position = ToastPosition.bottom,
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastWidget(
        message: message,
        type: type,
        duration: duration,
        position: position,
        onDone: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
  }

  static void success(BuildContext context, {required String message}) =>
      show(context, message: message, type: ToastType.success);

  static void error(BuildContext context, {required String message}) =>
      show(context, message: message, type: ToastType.error);

  static void warning(BuildContext context, {required String message}) =>
      show(context, message: message, type: ToastType.warning);

  static void info(BuildContext context, {required String message}) =>
      show(context, message: message, type: ToastType.info);
}

class _ToastWidget extends StatefulWidget {
  final String message;
  final ToastType type;
  final Duration duration;
  final ToastPosition position;
  final VoidCallback onDone;

  const _ToastWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.position,
    required this.onDone,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
    Future.delayed(widget.duration, () async {
      if (mounted) {
        await _controller.reverse();
        widget.onDone();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _bgColor {
    switch (widget.type) {
      case ToastType.success:
        return const Color(0xFF1B5E20);
      case ToastType.error:
        return const Color(0xFFB71C1C);
      case ToastType.warning:
        return const Color(0xFFE65100);
      case ToastType.info:
        return const Color(0xFF0D47A1);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case ToastType.success:
        return Icons.check_circle_rounded;
      case ToastType.error:
        return Icons.error_rounded;
      case ToastType.warning:
        return Icons.warning_rounded;
      case ToastType.info:
        return Icons.info_rounded;
    }
  }

  Alignment get _alignment {
    switch (widget.position) {
      case ToastPosition.top:
        return Alignment.topCenter;
      case ToastPosition.center:
        return Alignment.center;
      case ToastPosition.bottom:
        return Alignment.bottomCenter;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Align(
        alignment: _alignment,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: widget.position == ToastPosition.bottom ? 48 : 0,
            top: widget.position == ToastPosition.top ? 48 : 0,
            left: 24,
            right: 24,
          ),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _bgColor.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_icon, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            widget.message,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
