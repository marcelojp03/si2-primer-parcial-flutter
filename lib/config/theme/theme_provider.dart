import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final themeNotifierProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system);

  void setLight() => state = ThemeMode.light;
  void setDark() => state = ThemeMode.dark;
  void setSystem() => state = ThemeMode.system;

  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}
