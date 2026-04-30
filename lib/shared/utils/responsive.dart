import 'package:flutter/material.dart';
import 'dart:math' as math;

class Responsive {
  final double width;
  final double height;
  final double diagonal;
  final bool isMobile;
  final bool isTablet;
  final bool isDesktop;
  final bool isPortrait;

  factory Responsive.of(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diagonal = math.sqrt(
      math.pow(size.width, 2) + math.pow(size.height, 2),
    );
    final shortestSide = size.shortestSide;
    return Responsive._(
      width: size.width,
      height: size.height,
      diagonal: diagonal,
      isMobile: shortestSide < 600,
      isTablet: shortestSide >= 600 && shortestSide < 1024,
      isDesktop: shortestSide >= 1024,
      isPortrait: size.height >= size.width,
    );
  }

  const Responsive._({
    required this.width,
    required this.height,
    required this.diagonal,
    required this.isMobile,
    required this.isTablet,
    required this.isDesktop,
    required this.isPortrait,
  });

  double wp(double percent) => width * percent / 100;
  double hp(double percent) => height * percent / 100;
  double dp(double percent) => diagonal * percent / 100;

  double fontSize(double size) {
    if (isDesktop) return size * 1.2;
    if (isTablet) return size * 1.1;
    return size;
  }

  double spacing(double size) => isTablet ? size * 1.2 : size;
  double radius(double r) => isTablet ? r * 1.1 : r;
}

extension ResponsiveExtension on BuildContext {
  Responsive get responsive => Responsive.of(this);
}
