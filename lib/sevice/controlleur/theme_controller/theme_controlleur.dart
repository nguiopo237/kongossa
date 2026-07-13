// lib/sevice/controlleur/theme_controller/theme_controlleur.dart
// GetX controller for dark / light / system theme toggle with persistence

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static ThemeController get to => Get.find();

  static const String _themeKey = 'theme_mode';

  /// Reactive theme value. Can be read in main() BEFORE runApp() via future.
  final Rx<ThemeMode> currentTheme = ThemeMode.dark.obs;

  /// Loads theme from SharedPreferences and updates [currentTheme].
  /// Called in main() before runApp() to prevent flash.
  Future<void> loadSavedTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themeKey) ?? 'dark';
      switch (saved) {
        case 'light':
          currentTheme.value = ThemeMode.light;
          break;
        case 'system':
          currentTheme.value = ThemeMode.system;
          break;
        default:
          currentTheme.value = ThemeMode.dark;
      }
    } catch (e) {
      debugPrint('❌ Theme loading error: $e');
    }
  }

  Future<void> toggleTheme() async {
    final newMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    currentTheme.value = newMode;
    await _persistThemeMode(newMode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (currentTheme.value == mode) return;
    currentTheme.value = mode;
    await _persistThemeMode(mode);
  }

  Future<void> _persistThemeMode(ThemeMode mode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
        ThemeMode.dark => 'dark',
      };
      await prefs.setString(_themeKey, modeStr);
    } catch (e) {
      debugPrint('❌ Theme save error: $e');
    }
  }

  /// `true` if the (actual) active theme is dark.
  /// For [ThemeMode.system], uses system brightness via [MediaQuery].
  /// A [try/catch] protects against access outside the widget tree.
  bool get isDarkMode {
    if (currentTheme.value == ThemeMode.system) {
      try {
        return Get.mediaQuery.platformBrightness == Brightness.dark;
      } catch (_) {
        return true; // safe dark fallback
      }
    }
    return currentTheme.value == ThemeMode.dark;
  }

  /// Human-readable label for the current mode.
  String get currentLabel {
    switch (currentTheme.value) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
      case ThemeMode.dark:
        return 'Dark';
    }
  }
}
