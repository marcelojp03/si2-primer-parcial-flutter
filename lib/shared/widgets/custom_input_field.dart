import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:si2_p1_mobile/shared/utils/responsive.dart';

class CustomInputField extends StatefulWidget {
  final String label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? errorMessage;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final TextEditingController? controller;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;

  const CustomInputField({
    super.key,
    required this.label,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.errorMessage,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
  });

  @override
  State<CustomInputField> createState() => _CustomInputFieldState();
}

class _CustomInputFieldState extends State<CustomInputField> {
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() => _isFocused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final res = context.responsive;
    final theme = Theme.of(context);
    final hasError = widget.errorMessage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..scale(_isFocused ? 1.005 : 1.0),
          child: TextField(
            focusNode: _focusNode,
            controller: widget.controller,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            onChanged: widget.onChanged,
            readOnly: widget.readOnly,
            onTap: widget.onTap,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            style: GoogleFonts.inter(
              fontSize: res.fontSize(14),
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle: GoogleFonts.inter(
                fontSize: res.fontSize(14),
                color: hasError
                    ? theme.colorScheme.error
                    : _isFocused
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(
                      widget.prefixIcon,
                      size: res.fontSize(20),
                      color: hasError
                          ? theme.colorScheme.error
                          : _isFocused
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.5),
                    )
                  : null,
              suffixIcon: widget.suffixIcon,
              errorText: hasError ? widget.errorMessage : null,
            ),
          ),
        ),
      ],
    );
  }
}
