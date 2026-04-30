import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ===== Colores de marca =====
  static const Color primaryColor = Color(0xFFE53935); // Rojo emergencia
  static const Color secondaryColor = Color(0xFF1E88E5); // Azul confianza
  static const Color accentColor = Color(0xFFFFB300); // Ámbar alerta
  static const Color errorColor = Color(0xFFB71C1C);

  // Colores de estado incidente
  static const Color statusPending = Color(0xFF9E9E9E);
  static const Color statusNotified = Color(0xFF42A5F5);
  static const Color statusAccepted = Color(0xFF66BB6A);
  static const Color statusInProgress = Color(0xFFFFB300);
  static const Color statusAttended = Color(0xFF26A69A);
  static const Color statusCancelled = Color(0xFFEF5350);
  static const Color statusPaid = Color(0xFF4CAF50);

  // Prioridades
  static const Color priorityLow = Color(0xFF66BB6A);
  static const Color priorityMedium = Color(0xFFFFB300);
  static const Color priorityHigh = Color(0xFFFF7043);
  static const Color priorityCritical = Color(0xFFE53935);
  static const Color priorityUncertain = Color(0xFF9E9E9E);

  // Superficies
  static const Color surfaceLight = Color(0xFFF5F5F5);
  static const Color surfaceCardLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF121212);
  static const Color surfaceCardDark = Color(0xFF1E1E1E);

  // Gradiente de emergencia
  static const LinearGradient emergencyGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, Color(0xFFB71C1C)],
  );

  static ThemeData lightTheme() {
    return FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: primaryColor,
        primaryContainer: Color(0xFFFFCDD2),
        secondary: secondaryColor,
        secondaryContainer: Color(0xFFBBDEFB),
        tertiary: accentColor,
        tertiaryContainer: Color(0xFFFFECB3),
        error: errorColor,
      ),
      useMaterial3: true,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 4,
      visualDensity: VisualDensity.standard,
      scaffoldBackground: surfaceLight,
      surface: surfaceCardLight,
      appBarStyle: FlexAppBarStyle.background,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 8,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        bottomNavigationBarMutedUnselectedLabel: false,
        bottomNavigationBarMutedUnselectedIcon: false,
        bottomNavigationBarShowSelectedLabels: true,
        bottomNavigationBarShowUnselectedLabels: true,
        bottomNavigationBarType: BottomNavigationBarType.fixed,
        bottomNavigationBarBackgroundSchemeColor: SchemeColor.surface,
        bottomNavigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        bottomNavigationBarUnselectedLabelSchemeColor: SchemeColor.onSurface,
        bottomNavigationBarSelectedIconSchemeColor: SchemeColor.primary,
        bottomNavigationBarUnselectedIconSchemeColor: SchemeColor.onSurface,
        cardRadius: 16.0,
        elevatedButtonRadius: 12.0,
        filledButtonRadius: 12.0,
        outlinedButtonRadius: 12.0,
        textButtonRadius: 12.0,
        inputDecoratorRadius: 12.0,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorUnfocusedHasBorder: true,
        inputDecoratorFocusedHasBorder: true,
        inputDecoratorBorderWidth: 1.5,
        inputDecoratorFocusedBorderWidth: 2.0,
        fabRadius: 16.0,
        chipRadius: 10.0,
        dialogRadius: 20.0,
        snackBarRadius: 10.0,
        tabBarIndicatorWeight: 3.0,
        tabBarIndicatorTopRadius: 3.0,
        tabBarDividerColor: Colors.transparent,
      ),
      keyColors: const FlexKeyColors(
        useSecondary: true,
        useTertiary: true,
        keepPrimary: true,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      primaryTextTheme: GoogleFonts.interTextTheme(),
    );
  }

  static ThemeData darkTheme() {
    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: Color(0xFFEF9A9A),
        primaryContainer: Color(0xFFC62828),
        secondary: Color(0xFF90CAF9),
        secondaryContainer: Color(0xFF1565C0),
        tertiary: Color(0xFFFFD54F),
        tertiaryContainer: Color(0xFFE65100),
        error: Color(0xFFEF9A9A),
      ),
      useMaterial3: true,
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 12,
      visualDensity: VisualDensity.standard,
      scaffoldBackground: surfaceDark,
      surface: surfaceCardDark,
      appBarStyle: FlexAppBarStyle.background,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        cardRadius: 16.0,
        elevatedButtonRadius: 12.0,
        filledButtonRadius: 12.0,
        inputDecoratorRadius: 12.0,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        fabRadius: 16.0,
        chipRadius: 10.0,
        dialogRadius: 20.0,
      ),
      keyColors: const FlexKeyColors(
        useSecondary: true,
        useTertiary: true,
        keepPrimary: true,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      primaryTextTheme: GoogleFonts.interTextTheme(),
    );
  }

  // ===== Helpers de color por estado =====
  static Color incidentStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDIENTE':
        return statusPending;
      case 'NOTIFICADO':
        return statusNotified;
      case 'ACEPTADO':
        return statusAccepted;
      case 'EN_PROCESO':
        return statusInProgress;
      case 'ATENDIDO':
        return statusAttended;
      case 'CANCELADO':
        return statusCancelled;
      case 'PENDIENTE_PAGO':
        return statusInProgress;
      case 'PAGADO':
        return statusPaid;
      default:
        return statusPending;
    }
  }

  static Color priorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'BAJA':
        return priorityLow;
      case 'MEDIA':
        return priorityMedium;
      case 'ALTA':
        return priorityHigh;
      case 'CRITICA':
        return priorityCritical;
      default:
        return priorityUncertain;
    }
  }
}
