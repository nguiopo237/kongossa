import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fr.dart';
import 'en.dart';

class TranslationService extends Translations {
  static const String _localeKey = 'app_locale';

  // Fallback locale
  static const Locale fallbackLocale = Locale('fr', 'FR');

  // Supported locales
  static final List<Locale> supportedLocales = [
    const Locale('fr', 'FR'),
    const Locale('en', 'US'),
  ];

  @override
  Map<String, Map<String, String>> get keys => {
    ...FrMessages().keys,
    ...EnMessages().keys,
  };

  /// Get the current locale from SharedPreferences or default to French
  static Locale get currentLocale {
    final saved = _getSavedLocaleSync();
    return saved ?? fallbackLocale;
  }

  static Locale? _getSavedLocaleSync() {
    // This is a best-effort sync read; we also await in Future-based methods.
    return null; // Will be loaded asynchronously in main
  }

  /// Load saved locale from SharedPreferences
  static Future<Locale> loadSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString(_localeKey);
    if (langCode == 'en') return const Locale('en', 'US');
    return const Locale('fr', 'FR');
  }

  /// Save locale to SharedPreferences and switch
  static Future<void> switchLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
    Get.updateLocale(locale);
  }

  /// Get locale name in the user's language
  static String getLocaleName(Locale locale) {
    if (locale.languageCode == 'fr') return 'Français';
    if (locale.languageCode == 'en') return 'English';
    return locale.languageCode;
  }

  /// Get available locales for UI
  static List<LocaleOption> get localeOptions => [
    LocaleOption(locale: const Locale('fr', 'FR'), label: 'Français', nativeLabel: 'Français'),
    LocaleOption(locale: const Locale('en', 'US'), label: 'English', nativeLabel: 'English'),
  ];
}

class LocaleOption {
  final Locale locale;
  final String label;
  final String nativeLabel;

  LocaleOption({
    required this.locale,
    required this.label,
    required this.nativeLabel,
  });
}
