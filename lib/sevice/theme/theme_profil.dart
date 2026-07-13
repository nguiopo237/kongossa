// lib/sevice/theme/theme_profil.dart — Premium Dark & Light Themes

import 'package:flutter/material.dart';
import '../../config_App/colorsApp.dart';

class AppThemeProfil {
  // Premium Gold Colors (synchronisés avec ColorApp)
  static const Color premiumGold = ColorApp.premiumGold;
  static const Color premiumGoldLight = ColorApp.premiumGoldLight;
  static const Color premiumGoldDark = ColorApp.premiumGoldDark;
  static const Color premiumChampagne = ColorApp.premiumChampagne;

  // ── Couleurs Dark ──
  static const Color primaryColor = ColorApp.premiumGold;
  static const Color secondaryColor = ColorApp.premiumGoldLight;
  static const Color backgroundColor = ColorApp.darkVelvet;
  static const Color surfaceColor = ColorApp.darkSurface;
  static const Color cardColor = ColorApp.darkCard;
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFAAAAAA);
  static const Color textTertiary = Color(0xFF888888);
  static const Color dividerColor = Color(0xFF333333);

  // ── Couleurs Light ──
  static const Color lightBackground = Color(0xFFF5F5F5);
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;
  static const Color lightTextPrimary = Color(0xFF1D1E20);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightTextTertiary = Color(0xFF999999);
  static const Color lightDivider = Color(0xFFE0E0E0);
  static const Color lightInputFill = Color(0xFFF0F0F0);

  /// ──────────────────────────────────────────────────────────────────
  /// PREMIUM DARK THEME
  /// ──────────────────────────────────────────────────────────────────
  static ThemeData premiumDarkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    fontFamily: 'Intel',
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    dividerColor: dividerColor,
    splashColor: primaryColor.withValues(alpha: 0.12),
    highlightColor: primaryColor.withValues(alpha: 0.06),

    colorScheme: ColorScheme.dark(
      primary: primaryColor,
      onPrimary: Colors.black,
      primaryContainer: primaryColor.withValues(alpha: 0.15),
      onPrimaryContainer: primaryColor,
      secondary: secondaryColor,
      onSecondary: Colors.black,
      secondaryContainer: secondaryColor.withValues(alpha: 0.15),
      onSecondaryContainer: secondaryColor,
      tertiary: ColorApp.premiumChampagne,
      onTertiary: Colors.black,
      error: ColorApp.danger,
      onError: Colors.white,
      errorContainer: ColorApp.danger.withValues(alpha: 0.15),
      onErrorContainer: ColorApp.danger,
      surface: surfaceColor,
      onSurface: textPrimary,
      surfaceContainerHighest: cardColor,
      onSurfaceVariant: textSecondary,
      outline: dividerColor,
      outlineVariant: const Color(0xFF2A2A2A),
      shadow: Colors.black.withValues(alpha: 0.5),
      inverseSurface: const Color(0xFF2A2A2A),
      onInverseSurface: textPrimary,
      inversePrimary: premiumGoldLight,
      surfaceTint: primaryColor,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.3),
      iconTheme: IconThemeData(color: textPrimary, size: 22),
      actionsIconTheme: IconThemeData(color: textPrimary, size: 22),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: textSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
      selectedIconTheme: const IconThemeData(size: 24),
      unselectedIconTheme: const IconThemeData(size: 22),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surfaceColor,
      indicatorColor: primaryColor.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 12);
        }
        return const TextStyle(color: textSecondary, fontWeight: FontWeight.w400, fontSize: 11);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primaryColor, size: 24);
        }
        return const IconThemeData(color: textSecondary, size: 22);
      }),
      elevation: 8,
    ),

    textTheme: const TextTheme(
      displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 36, letterSpacing: -1.5),
      displayMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 28, letterSpacing: -0.5),
      displaySmall: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 24),
      headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: -0.3),
      headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 20),
      headlineSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 18),
      titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: -0.2),
      titleMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 14),
      titleSmall: TextStyle(color: textPrimary, fontWeight: FontWeight.w500, fontSize: 13),
      bodyLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w400, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(color: textSecondary, fontWeight: FontWeight.w400, fontSize: 14, height: 1.4),
      bodySmall: TextStyle(color: textTertiary, fontWeight: FontWeight.w400, fontSize: 12, height: 1.3),
      labelLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.5),
      labelMedium: TextStyle(color: textSecondary, fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.5),
      labelSmall: TextStyle(color: textTertiary, fontWeight: FontWeight.w500, fontSize: 10, letterSpacing: 0.5),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ColorApp.darkCharcoal,
      hintStyle: TextStyle(color: ColorApp.darkElevated.withValues(alpha: 0.6), fontSize: 14),
      labelStyle: TextStyle(color: textSecondary, fontSize: 14),
      errorStyle: const TextStyle(height: 0, color: ColorApp.danger),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: dividerColor, width: 1)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: dividerColor, width: 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: ColorApp.danger, width: 1)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: ColorApp.danger, width: 1.5)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: dividerColor.withValues(alpha: 0.5), width: 1)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIconColor: textSecondary,
      suffixIconColor: textSecondary,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: primaryColor,
        disabledBackgroundColor: primaryColor.withValues(alpha: 0.3),
        disabledForegroundColor: Colors.black.withValues(alpha: 0.4),
        elevation: 4,
        shadowColor: primaryColor.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.3),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        disabledForegroundColor: primaryColor.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        disabledForegroundColor: primaryColor.withValues(alpha: 0.4),
        side: BorderSide(color: dividerColor, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: dividerColor.withValues(alpha: 0.3), width: 0.5)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: surfaceColor,
      elevation: 16,
      shadowColor: Colors.black.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: dividerColor.withValues(alpha: 0.3), width: 0.5)),
      titleTextStyle: const TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.bold),
      contentTextStyle: const TextStyle(color: textSecondary, fontSize: 15, height: 1.4),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: ColorApp.darkElevated,
      contentTextStyle: const TextStyle(color: textPrimary, fontSize: 14),
      actionTextColor: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: dividerColor.withValues(alpha: 0.3), width: 0.5)),
      behavior: SnackBarBehavior.floating,
      elevation: 8,
      width: 320,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: ColorApp.darkCharcoal,
      selectedColor: primaryColor.withValues(alpha: 0.2),
      disabledColor: ColorApp.darkCharcoal.withValues(alpha: 0.5),
      labelStyle: const TextStyle(color: textSecondary, fontSize: 13),
      secondaryLabelStyle: const TextStyle(color: textPrimary, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: dividerColor, width: 0.5)),
      iconTheme: IconThemeData(color: primaryColor, size: 18),
      checkmarkColor: primaryColor,
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: ColorApp.darkElevated,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: dividerColor.withValues(alpha: 0.3), width: 0.5)),
      textStyle: const TextStyle(color: textPrimary, fontSize: 14),
      labelTextStyle: const WidgetStatePropertyAll(TextStyle(color: textPrimary, fontSize: 14)),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceColor,
      elevation: 12,
      modalElevation: 16,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      dragHandleColor: dividerColor,
      dragHandleSize: const Size(40, 4),
      showDragHandle: false,
      modalBackgroundColor: surfaceColor,
    ),

    iconTheme: const IconThemeData(color: textPrimary, size: 24),
    primaryIconTheme: const IconThemeData(color: primaryColor, size: 24),

    dividerTheme: const DividerThemeData(color: dividerColor, thickness: 0.5, space: 1),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        if (states.contains(WidgetState.disabled)) return dividerColor;
        return Colors.grey[600];
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor.withValues(alpha: 0.4);
        if (states.contains(WidgetState.disabled)) return dividerColor.withValues(alpha: 0.2);
        return dividerColor.withValues(alpha: 0.4);
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) => Colors.transparent),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.resolveWith((states) => Colors.black),
      side: BorderSide(color: dividerColor, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return dividerColor;
      }),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: primaryColor,
      inactiveTrackColor: dividerColor.withValues(alpha: 0.4),
      thumbColor: primaryColor,
      overlayColor: primaryColor.withValues(alpha: 0.12),
      valueIndicatorColor: primaryColor,
      valueIndicatorTextStyle: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(color: primaryColor, linearTrackColor: dividerColor, circularTrackColor: dividerColor),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.black,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      iconSize: 24,
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: textSecondary,
      indicatorColor: primaryColor,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: ColorApp.darkElevated, borderRadius: BorderRadius.circular(8), border: Border.all(color: dividerColor.withValues(alpha: 0.3))),
      textStyle: const TextStyle(color: textPrimary, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(ColorApp.darkElevated),
        elevation: const WidgetStatePropertyAll(8),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: dividerColor.withValues(alpha: 0.3)))),
      ),
    ),

    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStatePropertyAll(ColorApp.darkCharcoal),
      hintStyle: WidgetStatePropertyAll(TextStyle(color: textSecondary.withValues(alpha: 0.5))),
      textStyle: WidgetStatePropertyAll(const TextStyle(color: textPrimary)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide(color: dividerColor, width: 0.5))),
      elevation: const WidgetStatePropertyAll(0),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
    ),

    datePickerTheme: DatePickerThemeData(
      backgroundColor: surfaceColor,
      headerBackgroundColor: primaryColor,
      headerForegroundColor: Colors.black,
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.black;
        if (states.contains(WidgetState.disabled)) return textTertiary;
        return textPrimary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return Colors.transparent;
      }),
      todayForegroundColor: const WidgetStatePropertyAll(primaryColor),
      todayBackgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      todayBorder: const BorderSide(color: primaryColor, width: 1),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: dividerColor.withValues(alpha: 0.3))),
    ),

    timePickerTheme: TimePickerThemeData(
      backgroundColor: surfaceColor,
      hourMinuteColor: ColorApp.darkCharcoal,
      hourMinuteTextColor: textPrimary,
      dialBackgroundColor: ColorApp.darkCharcoal,
      dialHandColor: primaryColor,
      dialTextColor: textPrimary,
      entryModeIconColor: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: dividerColor.withValues(alpha: 0.3))),
    ),

    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: const TextStyle(color: textPrimary, fontSize: 16),
      subtitleTextStyle: TextStyle(color: textSecondary, fontSize: 13),
      iconColor: textSecondary,
      textColor: textPrimary,
      selectedTileColor: primaryColor.withValues(alpha: 0.08),
      selectedColor: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    expansionTileTheme: ExpansionTileThemeData(
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      iconColor: primaryColor,
      collapsedIconColor: textSecondary,
      textColor: textPrimary,
      collapsedTextColor: textPrimary,
      shape: Border(bottom: BorderSide(color: dividerColor.withValues(alpha: 0.3))),
      collapsedShape: const Border(),
      childrenPadding: const EdgeInsets.only(left: 16),
    ),
  );

  /// ──────────────────────────────────────────────────────────────────
  /// PREMIUM LIGHT THEME (symmetric to dark)
  /// ──────────────────────────────────────────────────────────────────
  static ThemeData premiumLightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: primaryColor,
    fontFamily: 'Intel',
    scaffoldBackgroundColor: lightBackground,
    cardColor: lightCard,
    dividerColor: lightDivider,
    splashColor: primaryColor.withValues(alpha: 0.12),
    highlightColor: primaryColor.withValues(alpha: 0.06),

    colorScheme: ColorScheme.light(
      primary: primaryColor,
      onPrimary: Colors.white,
      primaryContainer: primaryColor.withValues(alpha: 0.12),
      onPrimaryContainer: ColorApp.premiumGoldDark,
      secondary: secondaryColor,
      onSecondary: Colors.black,
      secondaryContainer: secondaryColor.withValues(alpha: 0.12),
      onSecondaryContainer: ColorApp.premiumGoldDark,
      tertiary: ColorApp.premiumChampagne,
      onTertiary: Colors.black,
      error: ColorApp.danger,
      onError: Colors.white,
      errorContainer: ColorApp.danger.withValues(alpha: 0.12),
      onErrorContainer: ColorApp.danger,
      surface: lightSurface,
      onSurface: lightTextPrimary,
      surfaceContainerHighest: lightCard,
      onSurfaceVariant: lightTextSecondary,
      outline: lightDivider,
      outlineVariant: const Color(0xFFEEEEEE),
      shadow: Colors.black.withValues(alpha: 0.1),
      inverseSurface: const Color(0xFF2A2A2A),
      onInverseSurface: Colors.white,
      inversePrimary: premiumGoldLight,
      surfaceTint: primaryColor,
    ),

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: false,
      titleTextStyle: TextStyle(color: lightTextPrimary, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: -0.3),
      iconTheme: IconThemeData(color: lightTextPrimary, size: 22),
      actionsIconTheme: IconThemeData(color: lightTextPrimary, size: 22),
    ),

    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: lightSurface,
      selectedItemColor: primaryColor,
      unselectedItemColor: lightTextSecondary,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 11),
      selectedIconTheme: const IconThemeData(size: 24),
      unselectedIconTheme: const IconThemeData(size: 22),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: lightSurface,
      indicatorColor: primaryColor.withValues(alpha: 0.12),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(color: primaryColor, fontWeight: FontWeight.w600, fontSize: 12);
        }
        return TextStyle(color: lightTextSecondary, fontWeight: FontWeight.w400, fontSize: 11);
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primaryColor, size: 24);
        }
        return IconThemeData(color: lightTextSecondary, size: 22);
      }),
      elevation: 8,
    ),

    textTheme: TextTheme(
      displayLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold, fontSize: 36, letterSpacing: -1.5),
      displayMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold, fontSize: 28, letterSpacing: -0.5),
      displaySmall: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold, fontSize: 24),
      headlineLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.bold, fontSize: 22, letterSpacing: -0.3),
      headlineMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 20),
      headlineSmall: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 18),
      titleLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 16, letterSpacing: -0.2),
      titleMedium: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w500, fontSize: 14),
      titleSmall: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w500, fontSize: 13),
      bodyLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w400, fontSize: 16, height: 1.5),
      bodyMedium: TextStyle(color: lightTextSecondary, fontWeight: FontWeight.w400, fontSize: 14, height: 1.4),
      bodySmall: TextStyle(color: lightTextTertiary, fontWeight: FontWeight.w400, fontSize: 12, height: 1.3),
      labelLarge: TextStyle(color: lightTextPrimary, fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.5),
      labelMedium: TextStyle(color: lightTextSecondary, fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.5),
      labelSmall: TextStyle(color: lightTextTertiary, fontWeight: FontWeight.w500, fontSize: 10, letterSpacing: 0.5),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightInputFill,
      hintStyle: TextStyle(color: lightTextTertiary, fontSize: 14),
      labelStyle: TextStyle(color: lightTextSecondary, fontSize: 14),
      errorStyle: const TextStyle(height: 0, color: ColorApp.danger),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightDivider, width: 1)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightDivider, width: 1)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: primaryColor, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: ColorApp.danger, width: 1)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: ColorApp.danger, width: 1.5)),
      disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: lightDivider.withValues(alpha: 0.5), width: 1)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIconColor: lightTextSecondary,
      suffixIconColor: lightTextSecondary,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        disabledBackgroundColor: primaryColor.withValues(alpha: 0.3),
        disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
        elevation: 2,
        shadowColor: primaryColor.withValues(alpha: 0.3),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.3),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        disabledForegroundColor: primaryColor.withValues(alpha: 0.4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        disabledForegroundColor: primaryColor.withValues(alpha: 0.4),
        side: BorderSide(color: lightDivider, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),

    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 2,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: lightDivider.withValues(alpha: 0.5), width: 0.5)),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      clipBehavior: Clip.antiAlias,
    ),

    dialogTheme: DialogThemeData(
      backgroundColor: lightSurface,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: lightDivider.withValues(alpha: 0.5), width: 0.5)),
      titleTextStyle: TextStyle(color: lightTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
      contentTextStyle: TextStyle(color: lightTextSecondary, fontSize: 15, height: 1.4),
    ),

    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightTextPrimary,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      actionTextColor: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: lightDivider.withValues(alpha: 0.3), width: 0.5)),
      behavior: SnackBarBehavior.floating,
      elevation: 4,
      width: 320,
    ),

    chipTheme: ChipThemeData(
      backgroundColor: lightInputFill,
      selectedColor: primaryColor.withValues(alpha: 0.15),
      disabledColor: lightInputFill.withValues(alpha: 0.5),
      labelStyle: TextStyle(color: lightTextSecondary, fontSize: 13),
      secondaryLabelStyle: TextStyle(color: lightTextPrimary, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: lightDivider, width: 0.5)),
      iconTheme: IconThemeData(color: primaryColor, size: 18),
      checkmarkColor: primaryColor,
    ),

    popupMenuTheme: PopupMenuThemeData(
      color: lightSurface,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: lightDivider.withValues(alpha: 0.5), width: 0.5)),
      textStyle: TextStyle(color: lightTextPrimary, fontSize: 14),
      labelTextStyle: WidgetStatePropertyAll(TextStyle(color: lightTextPrimary, fontSize: 14)),
    ),

    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: lightSurface,
      elevation: 8,
      modalElevation: 12,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      dragHandleColor: lightDivider,
      dragHandleSize: const Size(40, 4),
      showDragHandle: false,
      modalBackgroundColor: lightSurface,
    ),

    iconTheme: IconThemeData(color: lightTextPrimary, size: 24),
    primaryIconTheme: const IconThemeData(color: primaryColor, size: 24),

    dividerTheme: const DividerThemeData(color: Color(0xFFE0E0E0), thickness: 0.5, space: 1),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        if (states.contains(WidgetState.disabled)) return lightDivider;
        return Colors.grey[400];
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor.withValues(alpha: 0.4);
        if (states.contains(WidgetState.disabled)) return lightDivider.withValues(alpha: 0.2);
        return lightDivider.withValues(alpha: 0.6);
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((states) => Colors.transparent),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.resolveWith((states) => Colors.white),
      side: BorderSide(color: lightDivider, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return lightDivider;
      }),
    ),

    sliderTheme: SliderThemeData(
      activeTrackColor: primaryColor,
      inactiveTrackColor: lightDivider.withValues(alpha: 0.4),
      thumbColor: primaryColor,
      overlayColor: primaryColor.withValues(alpha: 0.12),
      valueIndicatorColor: primaryColor,
      valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      trackHeight: 4,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
    ),

    progressIndicatorTheme: ProgressIndicatorThemeData(color: primaryColor, linearTrackColor: lightDivider, circularTrackColor: lightDivider),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      iconSize: 24,
    ),

    tabBarTheme: TabBarThemeData(
      labelColor: primaryColor,
      unselectedLabelColor: lightTextSecondary,
      indicatorColor: primaryColor,
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: lightTextPrimary, borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(color: Colors.white, fontSize: 13),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(lightSurface),
        elevation: const WidgetStatePropertyAll(4),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: lightDivider.withValues(alpha: 0.5)))),
      ),
    ),

    searchBarTheme: SearchBarThemeData(
      backgroundColor: WidgetStatePropertyAll(lightInputFill),
      hintStyle: WidgetStatePropertyAll(TextStyle(color: lightTextTertiary)),
      textStyle: WidgetStatePropertyAll(TextStyle(color: lightTextPrimary)),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: BorderRadius.circular(30), side: BorderSide(color: lightDivider, width: 0.5))),
      elevation: const WidgetStatePropertyAll(0),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
    ),

    datePickerTheme: DatePickerThemeData(
      backgroundColor: lightSurface,
      headerBackgroundColor: primaryColor,
      headerForegroundColor: Colors.white,
      dayForegroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return Colors.white;
        if (states.contains(WidgetState.disabled)) return lightTextTertiary;
        return lightTextPrimary;
      }),
      dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return primaryColor;
        return Colors.transparent;
      }),
      todayForegroundColor: const WidgetStatePropertyAll(primaryColor),
      todayBackgroundColor: const WidgetStatePropertyAll(Colors.transparent),
      todayBorder: const BorderSide(color: primaryColor, width: 1),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: lightDivider.withValues(alpha: 0.5))),
    ),

    timePickerTheme: TimePickerThemeData(
      backgroundColor: lightSurface,
      hourMinuteColor: lightInputFill,
      hourMinuteTextColor: lightTextPrimary,
      dialBackgroundColor: lightInputFill,
      dialHandColor: primaryColor,
      dialTextColor: lightTextPrimary,
      entryModeIconColor: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: lightDivider.withValues(alpha: 0.5))),
    ),

    listTileTheme: ListTileThemeData(
      tileColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      titleTextStyle: TextStyle(color: lightTextPrimary, fontSize: 16),
      subtitleTextStyle: TextStyle(color: lightTextSecondary, fontSize: 13),
      iconColor: lightTextSecondary,
      textColor: lightTextPrimary,
      selectedTileColor: primaryColor.withValues(alpha: 0.08),
      selectedColor: primaryColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),

    expansionTileTheme: ExpansionTileThemeData(
      backgroundColor: Colors.transparent,
      collapsedBackgroundColor: Colors.transparent,
      iconColor: primaryColor,
      collapsedIconColor: lightTextSecondary,
      textColor: lightTextPrimary,
      collapsedTextColor: lightTextPrimary,
      shape: Border(bottom: BorderSide(color: lightDivider.withValues(alpha: 0.5))),
      collapsedShape: const Border(),
      childrenPadding: const EdgeInsets.only(left: 16),
    ),
  );

  /// Old reference kept for compatibility
  static ThemeData get darkTheme => premiumDarkTheme;
}
