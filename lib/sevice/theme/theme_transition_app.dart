// lib/sevice/theme/theme_transition_app.dart
// Root widget that animates the transition between dark/light themes with a cross-fade.

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../i18n/translation_service.dart';
import 'theme_profil.dart';
import 'theme_switcher_provider.dart';

/// Root application widget.
///
/// Uses an overlay with [AnimationController] for a smooth cross-fade
/// between old and new themes. [homeBuilder] creates two separate
/// instances of the app content: one for the overlay (old theme)
/// and one for the main content (new theme).
class ThemeTransitionApp extends StatefulWidget {
  final String title;
  final WidgetBuilder homeBuilder;
  final VoidCallback? onInit;
  final bool debugShowCheckedModeBanner;
  final bool enableLog;
  final List<GetPage>? getPages;

  const ThemeTransitionApp({
    super.key,
    required this.title,
    required this.homeBuilder,
    this.onInit,
    this.debugShowCheckedModeBanner = false,
    this.enableLog = false,
    this.getPages,
  });

  @override
  State<ThemeTransitionApp> createState() => _ThemeTransitionAppState();
}

class _ThemeTransitionAppState extends State<ThemeTransitionApp>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeOut;
  ThemeData? _oldThemeData;
  ThemeMode _lastMode = ThemeMode.dark;
  Worker? _themeWorker;

  bool get _isTransitioning => _oldThemeData != null;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeOut = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOutCubic,
    );
    _lastMode = ThemeSwitcherProvider.currentMode;

    // Watch for theme changes
    _themeWorker = ever(ThemeSwitcherProvider.controller.currentTheme, (_) => _onThemeChanged());
  }

  void _onThemeChanged() {
    final newMode = ThemeSwitcherProvider.currentMode;
    if (newMode == _lastMode) return;

    // ⚠️ Save OLD ThemeData BEFORE updating _lastMode
    _oldThemeData = _themeDataForMode(_lastMode);
    _lastMode = newMode;

    // Start overlay fade: old theme (opacity 1) → disappears (opacity 0)
    _fadeController
      ..value = 1.0
      ..reverse()
      .then((_) {
        if (mounted) {
          setState(() => _oldThemeData = null);
        }
      });
    // Force rebuild to show overlay
    setState(() {});
  }

  /// Returns [ThemeData] for a given theme mode.
  /// For [ThemeMode.system], reads system brightness via [Get.mediaQuery].
  static ThemeData _themeDataForMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return AppThemeProfil.premiumLightTheme;
      case ThemeMode.dark:
        return AppThemeProfil.premiumDarkTheme;
      case ThemeMode.system:
        try {
          return Get.mediaQuery.platformBrightness == Brightness.dark
              ? AppThemeProfil.premiumDarkTheme
              : AppThemeProfil.premiumLightTheme;
        } catch (_) {
          return AppThemeProfil.premiumDarkTheme;
        }
    }
  }

  @override
  void dispose() {
    _themeWorker?.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mode = ThemeSwitcherProvider.currentMode;
    return GetMaterialApp(
      title: widget.title,
      debugShowCheckedModeBanner: widget.debugShowCheckedModeBanner,
      theme: AppThemeProfil.premiumLightTheme,
      darkTheme: AppThemeProfil.premiumDarkTheme,
      themeMode: mode,

      // ── Internationalisation (GetX) ──
      translations: TranslationService(),
      locale: TranslationService.currentLocale,
      fallbackLocale: TranslationService.fallbackLocale,
      supportedLocales: TranslationService.supportedLocales,

      enableLog: widget.enableLog,
      onInit: widget.onInit,
      getPages: widget.getPages,
      home: Stack(
        children: [
          // Instance A: new theme (rendered underneath)
          widget.homeBuilder(context),
          // Instance B: old theme in overlay (fading out)
          if (_isTransitioning)
            Theme(
              data: _oldThemeData!,
              child: FadeTransition(
                opacity: _fadeOut,
                child: RepaintBoundary(
                  child: IgnorePointer(
                    child: widget.homeBuilder(context),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
