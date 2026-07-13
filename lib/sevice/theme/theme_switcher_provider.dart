// lib/sevice/theme/theme_switcher_provider.dart
// ThemeSwitcherProvider — GetX Provider to dynamically toggle between light & dark theme

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controlleur/theme_controller/theme_controlleur.dart';
import 'theme_profil.dart';
import 'theme_transition_app.dart';

/// GetX Provider for reactive dark/light theme management.
///
/// Usage:
/// ```dart
/// // In main.dart:
/// ThemeSwitcherProvider.buildApp(
///   title: 'Kongossa',
///   home: SplashScreen(),
/// )
///
/// // Anywhere in the app:
/// ThemeSwitcherProvider.of.toggleTheme();
/// bool isDark = ThemeSwitcherProvider.isDarkMode;
/// ThemeData theme = ThemeSwitcherProvider.currentTheme;
/// ```
class ThemeSwitcherProvider {
  ThemeSwitcherProvider._();

  // ── Access to underlying controller ──

  /// Unique instance of theme controller (delegates to [ThemeController.to]).
  static ThemeController get controller => ThemeController.to;

  /// Currently active theme (dark or light).
  static ThemeMode get currentMode => controller.currentTheme.value;

  /// `true` if dark theme is active.
  static bool get isDarkMode => controller.isDarkMode;

  /// `true` if light theme is active.
  static bool get isLightMode => !controller.isDarkMode;

  // ── Material Themes ──

  /// `ThemeData` for the active theme.
  static ThemeData get currentTheme =>
      isDarkMode ? AppThemeProfil.premiumDarkTheme : AppThemeProfil.premiumLightTheme;

  /// `ThemeData` for dark theme.
  static ThemeData get darkTheme => AppThemeProfil.premiumDarkTheme;

  /// `ThemeData` for light theme.
  static ThemeData get lightTheme => AppThemeProfil.premiumLightTheme;

  // ── Actions ──

  /// Toggle between dark and light theme.
  static Future<void> toggleTheme() => controller.toggleTheme();

  /// Set a specific theme mode.
  static Future<void> setThemeMode(ThemeMode mode) => controller.setThemeMode(mode);

  /// Human-readable label for current mode ("Dark", "System", "Light").
  static String get currentLabel => controller.currentLabel;

  /// Load saved theme from SharedPreferences.
  static Future<void> loadSavedTheme() => controller.loadSavedTheme();

  // ── Widget builder ──

  /// Builds a `GetMaterialApp` reactive to theme changes.
  ///
  /// Usage in `main.dart`:
  /// ```dart
  /// return ResponsiveSizer(
  ///   builder: (context, orientation, screenType) {
  ///     return ThemeSwitcherProvider.buildApp(
  ///       title: 'Kongossa',
  ///       home: SplashScreen(),
  ///     );
  ///   },
  /// );
  /// ```
  static Widget buildApp({
    required String title,
    required WidgetBuilder homeBuilder,
    bool debugShowCheckedModeBanner = false,
    bool enableLog = false,
    VoidCallback? onInit,
    List<GetPage>? getPages,
  }) {
    return ThemeTransitionApp(
      title: title,
      homeBuilder: homeBuilder,
      onInit: onInit,
      debugShowCheckedModeBanner: debugShowCheckedModeBanner,
      enableLog: enableLog,
      getPages: getPages,
    );
  }
}
