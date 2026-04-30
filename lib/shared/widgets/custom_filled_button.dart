import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:si2_p1_mobile/shared/utils/responsive.dart';

class CustomFilledButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final Color? buttonColor;
  final Color? textColor;
  final double height;
  final bool isOutlined;
  final IconData? icon;

  const CustomFilledButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.buttonColor,
    this.textColor,
    this.height = 52,
    this.isOutlined = false,
    this.icon,
  });

  @override
  State<CustomFilledButton> createState() => _CustomFilledButtonState();
}

class _CustomFilledButtonState extends State<CustomFilledButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final res = context.responsive;
    final theme = Theme.of(context);
    final Color color = widget.buttonColor ?? theme.colorScheme.primary;
    final Color textColor = widget.textColor ?? Colors.white;
    final bool isActive =
        widget.isEnabled && widget.onPressed != null && !widget.isLoading;

    Widget buttonChild = widget.isLoading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: res.fontSize(18), color: textColor),
                SizedBox(width: res.spacing(8)),
              ],
              Text(
                widget.text,
                style: GoogleFonts.inter(
                  fontSize: res.fontSize(15),
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ],
          );

    return SizedBox(
      width: double.infinity,
      height: widget.height,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          child: widget.isOutlined
              ? OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    minimumSize: Size(double.infinity, widget.height),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(res.radius(12)),
                    ),
                    side: BorderSide(
                      color: isActive ? color : color.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  onPressed: isActive ? widget.onPressed : null,
                  child: buttonChild,
                )
              : ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? color : color.withOpacity(0.45),
                    foregroundColor: textColor,
                    minimumSize: Size(double.infinity, widget.height),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(res.radius(12)),
                    ),
                    elevation: 0,
                  ),
                  onPressed: isActive ? widget.onPressed : null,
                  child: buttonChild,
                ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}
