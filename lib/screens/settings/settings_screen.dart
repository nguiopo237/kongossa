// lib/screens/settings/settings_screen.dart
// Écran de réglages complet : thème, notifications, préférences utilisateur.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../model/datamodel/user_model.dart';
import '../../sevice/controlleur/authentification/auth_controlleur.dart';
import '../../sevice/controlleur/firestore_collections_service.dart';
import '../../sevice/i18n/translation_service.dart';
import '../../sevice/theme/theme_switcher_provider.dart';

/// Clé SharedPreferences pour les préférences utilisateur.
class _PrefKeys {
  static const notificationsEnabled = 'pref_notifications_enabled';
  static const notificationsMessages = 'pref_notifications_messages';
  static const notificationsLikes = 'pref_notifications_likes';
  static const notificationsComments = 'pref_notifications_comments';
  static const autoDownload = 'pref_auto_download';
  static const videoQuality = 'pref_video_quality';
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Helpers de couleurs adaptatives ──

  /// Fond de scène depuis le thème actif.
  Color get _bg => Theme.of(context).colorScheme.surface;

  /// `ColorScheme.primary` (premiumGold).
  Color get _gold => Theme.of(context).colorScheme.primary;

  /// `onSurface` (texte principal).
  Color get _onSurface => Theme.of(context).colorScheme.onSurface;

  /// `onSurfaceVariant` (texte secondaire/subtil).
  Color get _subtle => Theme.of(context).colorScheme.onSurfaceVariant;

  /// `outline` (bordures).
  Color get _outline => Theme.of(context).colorScheme.outline;

  /// Fond des cartes.
  Color get _surface => Theme.of(context).colorScheme.surface;

  /// `error` (couleur danger/erreur).
  Color get _error => Theme.of(context).colorScheme.error;

  // ── Notifications ──
  bool _notifEnabled = true;
  bool _notifMessages = true;
  bool _notifLikes = true;
  bool _notifComments = true;

  // ── Préférences ──
  bool _autoDownload = false;
  String _videoQuality = 'Auto';

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notifEnabled = prefs.getBool(_PrefKeys.notificationsEnabled) ?? true;
        _notifMessages = prefs.getBool(_PrefKeys.notificationsMessages) ?? true;
        _notifLikes = prefs.getBool(_PrefKeys.notificationsLikes) ?? true;
        _notifComments = prefs.getBool(_PrefKeys.notificationsComments) ?? true;
        _autoDownload = prefs.getBool(_PrefKeys.autoDownload) ?? false;
        _videoQuality = prefs.getString(_PrefKeys.videoQuality) ?? 'Auto';
        _isLoading = false;
      });
    } catch (e) {
      _isLoading = false;
    }
  }

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(                  title: Text(
                    'settings.title'.tr,
                    style: TextStyle(color: _onSurface, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: _gold),
          onPressed: () => Get.back(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
              children: [
                _buildSectionHeader('settings.theme'.tr, Icons.palette_outlined, _gold),
                _buildThemeCard(),

                SizedBox(height: 3.h),
                _buildSectionHeader('settings.notifications'.tr, Icons.notifications_outlined, _gold),
                _buildNotifCard(),

                SizedBox(height: 3.h),
                _buildSectionHeader('settings.preferences'.tr, Icons.tune_outlined, _gold),
                _buildPrefsCard(),

                SizedBox(height: 3.h),
                _buildSectionHeader('settings.account'.tr, Icons.person_outline, _gold),
                _buildAccountCard(),

                SizedBox(height: 3.h),
                _buildSectionHeader('settings.about'.tr, Icons.info_outline, _gold),
                _buildAboutCard(),

                SizedBox(height: 5.h),
              ],
            ),
    );
  }

  // ── En-tête de section ──

  Widget _buildSectionHeader(String label, IconData icon, Color color) {
    return Padding(
      padding: EdgeInsets.only(left: 1.w, bottom: 1.5.h),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          SizedBox(width: 2.w),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Carte générique ──

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _gold.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  // ── Widget de réglage standard (icône + label + switch) ──

  Widget _buildSettingRow({
    required IconData icon,
    required String label,
    required String? subtitle,
    required Color iconColor,
    required Color textColor,
    required Color subtitleColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 0.8.h),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: textColor, fontSize: 14, fontWeight: FontWeight.w500)),
                  if (subtitle != null)
                    Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 12)),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  THÈME
  // ═══════════════════════════════════════════════

  Widget _buildThemePreview() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _outline.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          // ── En-tête de la preview ──
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.palette_outlined, size: 16, color: _gold),
              ),
              SizedBox(width: 2.5.w),
              Text(
                'settings.theme_preview'.tr,
                style: TextStyle(
                  color: _onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Divider(height: 1, color: _outline.withValues(alpha: 0.15)),
          SizedBox(height: 1.5.h),

          // ── Échantillons de couleurs ──
          Row(
            children: [
              _buildColorSwatch(_gold, 'settings.primary'.tr),
              SizedBox(width: 2.w),
              _buildColorSwatch(_onSurface, 'settings.text'.tr),
              SizedBox(width: 2.w),
              _buildColorSwatch(_subtle, 'settings.secondary'.tr),
              SizedBox(width: 2.w),
              _buildColorSwatch(_error, 'settings.error'.tr),
            ],
          ),
          SizedBox(height: 1.5.h),

          // ── Texte exemple ──
          RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, height: 1.5),
              children: [
                TextSpan(
                  text: 'settings.main_text'.tr,
                  style: TextStyle(color: _onSurface, fontWeight: FontWeight.w500),
                ),
                TextSpan(
                  text: 'settings.secondary_text'.tr,
                  style: TextStyle(color: _subtle),
                ),
              ],
            ),
          ),
          SizedBox(height: 1.5.h),

          // ── Bouton exemple réactif ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                disabledBackgroundColor: _gold.withValues(alpha: 0.6),
                disabledForegroundColor: Colors.black.withValues(alpha: 0.6),
                padding: EdgeInsets.symmetric(vertical: 1.2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rounded, size: 16),
                  SizedBox(width: 2.w),
                  Text(
                    'settings.premium_button'.tr,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 1.5.h),

          // ── Switch et TextField ──
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.notifications_outlined, size: 14, color: _gold),
                    SizedBox(width: 2.w),
                    Text(
                      'settings.notifications'.tr,
                      style: TextStyle(fontSize: 12, color: _onSurface),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: true,
                onChanged: null,
                activeThumbColor: _gold,
                activeTrackColor: _gold.withValues(alpha: 0.4),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          TextField(
            enabled: false,
            decoration: InputDecoration(
              hintText: 'settings.text_field'.tr,
              hintStyle: TextStyle(color: _subtle, fontSize: 13),
              filled: true,
              fillColor: _surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _outline.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: _outline.withValues(alpha: 0.3)),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 3.w,
                vertical: 1.2.h,
              ),
            ),
            style: TextStyle(color: _onSurface, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSwatch(Color color, String label) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _outline.withValues(alpha: 0.1),
              ),
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            label,
            style: TextStyle(
              color: _subtle,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard() {
    return _buildCard(
      child: Obx(() {
        final currentMode = ThemeSwitcherProvider.currentMode;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingRow(
              icon: currentMode == ThemeMode.light
                  ? Icons.light_mode_outlined
                  : currentMode == ThemeMode.system
                      ? Icons.brightness_auto_outlined
                      : Icons.dark_mode_outlined,
              label: 'settings.display_mode'.tr,
              subtitle: ThemeSwitcherProvider.currentLabel,
              iconColor: _gold,
              textColor: _onSurface,
              subtitleColor: _subtle,
            ),
            SizedBox(height: 1.h),
            SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.dark, label: Text('profile.dark'.tr), icon: Icon(Icons.dark_mode_outlined, size: 18)),
                ButtonSegment(value: ThemeMode.system, label: Text('profile.system'.tr), icon: Icon(Icons.brightness_auto_outlined, size: 18)),
                ButtonSegment(value: ThemeMode.light, label: Text('profile.light'.tr), icon: Icon(Icons.light_mode_outlined, size: 18)),
              ],
              selected: {currentMode},
              onSelectionChanged: (Set<ThemeMode> sel) => ThemeSwitcherProvider.setThemeMode(sel.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) return _gold.withValues(alpha: 0.2);
                  return Colors.transparent;
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) return _gold;
                  return _subtle;
                }),
                side: WidgetStateProperty.resolveWith<BorderSide>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return BorderSide(color: _gold.withValues(alpha: 0.5));
                  }
                  return BorderSide(color: _outline.withValues(alpha: 0.3));
                }),
                shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                padding: WidgetStateProperty.all(EdgeInsets.symmetric(vertical: 1.h)),
              ),
            ),

            SizedBox(height: 2.h),
            _buildThemePreview(),
          ],
        );
      }),
    );
  }

  // ═══════════════════════════════════════════════
  //  NOTIFICATIONS
  // ═══════════════════════════════════════════════

  Widget _buildNotifCard() {
    return _buildCard(
      child: Column(
        children: [
          _buildSettingRow(
            icon: Icons.notifications_active_outlined,
            label: 'settings.push_notifications'.tr,
            subtitle: _notifEnabled ? 'settings.enabled'.tr : 'settings.disabled'.tr,
            iconColor: _notifEnabled ? _gold : _subtle,
            textColor: _onSurface,
            subtitleColor: _subtle,
            trailing: Switch.adaptive(
              value: _notifEnabled,
              onChanged: (val) {
                setState(() => _notifEnabled = val);
                _saveBool(_PrefKeys.notificationsEnabled, val);
              },
              activeThumbColor: _gold,
              activeTrackColor: _gold.withValues(alpha: 0.4),
            ),
          ),
          Divider(height: 1, color: _outline.withValues(alpha: 0.2)),
          _buildSettingRow(
            icon: Icons.chat_outlined,
            label: 'settings.messages'.tr,
            iconColor: _notifMessages ? _gold : _subtle,
            textColor: _onSurface,
            subtitleColor: _subtle,
            subtitle: _notifMessages ? 'settings.notif_messages'.tr : 'settings.silent'.tr,
            trailing: Switch.adaptive(
              value: _notifMessages,
              onChanged: _notifEnabled
                  ? (val) {
                      setState(() => _notifMessages = val);
                      _saveBool(_PrefKeys.notificationsMessages, val);
                    }
                  : null,
              activeThumbColor: _gold,
              activeTrackColor: _gold.withValues(alpha: 0.4),
            ),
          ),
          Divider(height: 1, color: _outline.withValues(alpha: 0.2)),
          _buildSettingRow(
            icon: Icons.favorite_outline,
            label: 'settings.likes'.tr,
            iconColor: _notifLikes ? _gold : _subtle,
            textColor: _onSurface,
            subtitleColor: _subtle,
            subtitle: _notifLikes ? 'settings.notif_likes'.tr : 'settings.silent'.tr,
            trailing: Switch.adaptive(
              value: _notifLikes,
              onChanged: _notifEnabled
                  ? (val) {
                      setState(() => _notifLikes = val);
                      _saveBool(_PrefKeys.notificationsLikes, val);
                    }
                  : null,
              activeThumbColor: _gold,
              activeTrackColor: _gold.withValues(alpha: 0.4),
            ),
          ),
          Divider(height: 1, color: _outline.withValues(alpha: 0.2)),
          _buildSettingRow(
            icon: Icons.comment_outlined,
            label: 'settings.comments'.tr,
            iconColor: _notifComments ? _gold : _subtle,
            textColor: _onSurface,
            subtitleColor: _subtle,
            subtitle: _notifComments ? 'settings.notif_comments'.tr : 'settings.silent'.tr,
            trailing: Switch.adaptive(
              value: _notifComments,
              onChanged: _notifEnabled
                  ? (val) {
                      setState(() => _notifComments = val);
                      _saveBool(_PrefKeys.notificationsComments, val);
                    }
                  : null,
              activeThumbColor: _gold,
              activeTrackColor: _gold.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  PRÉFÉRENCES
  // ═══════════════════════════════════════════════

  Widget _buildPrefsCard() {
    return _buildCard(
      child: Column(
        children: [
          _buildSettingRow(
            icon: Icons.download_outlined,
            label: 'settings.auto_download'.tr,
            subtitle: _autoDownload ? 'settings.wifi_data'.tr : 'settings.wifi_only'.tr,
            iconColor: _gold,
            textColor: _onSurface,
            subtitleColor: _subtle,
            trailing: Switch.adaptive(
              value: _autoDownload,
              onChanged: (val) {
                setState(() => _autoDownload = val);
                _saveBool(_PrefKeys.autoDownload, val);
              },
              activeThumbColor: _gold,
              activeTrackColor: _gold.withValues(alpha: 0.4),
            ),
          ),
          Divider(height: 1, color: _outline.withValues(alpha: 0.2)),
          _buildSettingRow(
            icon: Icons.high_quality_outlined,
            label: 'settings.video_quality'.tr,
            subtitle: _videoQuality,
            iconColor: _gold,
            textColor: _onSurface,
            subtitleColor: _subtle,
            trailing: Container(
              padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.3.h),
              decoration: BoxDecoration(
                color: _gold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _videoQuality,
                  dropdownColor: _surface,
                  style: TextStyle(color: _gold, fontSize: 13),
                  icon: Icon(Icons.expand_more, size: 16, color: _gold),
                  items: [
                    DropdownMenuItem(value: 'settings.auto'.tr, child: Text('settings.auto'.tr)),
                    DropdownMenuItem(value: 'settings.high'.tr, child: Text('settings.high'.tr)),
                    DropdownMenuItem(value: 'settings.medium'.tr, child: Text('settings.medium'.tr)),
                    DropdownMenuItem(value: 'settings.low'.tr, child: Text('settings.low'.tr)),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _videoQuality = val);
                      _saveString(_PrefKeys.videoQuality, val);
                    }
                  },
                ),
              ),
            ),
          ),
          Divider(height: 1, color: _outline.withValues(alpha: 0.2)),
          _buildLanguageRow(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  LANGUE
  // ═══════════════════════════════════════════════

  Widget _buildLanguageRow() {
    return Obx(() {
      return _buildSettingRow(
        icon: Icons.language_outlined,
        label: 'settings.language'.tr,
        subtitle: TranslationService.getLocaleName(Get.locale ?? TranslationService.fallbackLocale),
        iconColor: _gold,
        textColor: _onSurface,
        subtitleColor: _subtle,
        trailing: Icon(Icons.chevron_right, color: _subtle, size: 20),
        onTap: () => _showLanguagePicker(),
      );
    });
  }

  void _showLanguagePicker() {
    final currentLocale = Get.locale ?? TranslationService.fallbackLocale;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 2.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poignée de glissement
            Container(
              margin: EdgeInsets.symmetric(vertical: 1.5.h),
              width: 10.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: _outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Titre
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.h),
              child: Row(
                children: [
                  Icon(Icons.language_outlined, size: 20, color: _gold),
                  SizedBox(width: 3.w),
                  Text(
                    'settings.language'.tr,
                    style: TextStyle(
                      color: _onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
            Divider(height: 1, color: _outline.withValues(alpha: 0.2)),
            SizedBox(height: 1.h),

            // Options de langue
            ...TranslationService.localeOptions.map((option) {
              final isSelected = option.locale.languageCode == currentLocale.languageCode;
              return _buildLanguageOption(
                localeOption: option,
                isSelected: isSelected,
                onTap: () {
                  Navigator.pop(ctx);
                  TranslationService.switchLocale(option.locale);
                },
              );
            }),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required LocaleOption localeOption,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 1.2.h),
        child: Row(
          children: [
            // Drapeau / icône
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? _gold.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? _gold.withValues(alpha: 0.5) : _outline.withValues(alpha: 0.2),
                ),
              ),
              child: Center(
                child: Text(
                  localeOption.locale.languageCode == 'fr' ? '🇫🇷' : '🇬🇧',
                  style: TextStyle(fontSize: 18.sp),
                ),
              ),
            ),
            SizedBox(width: 3.w),
            // Nom de la langue
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localeOption.label,
                    style: TextStyle(
                      color: _onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    localeOption.nativeLabel,
                    style: TextStyle(
                      color: _subtle,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            // Sélecteur radio
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? _gold : _outline.withValues(alpha: 0.5),
                  width: 2,
                ),
                color: isSelected ? _gold : Colors.transparent,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  COMPTE
  // ═══════════════════════════════════════════════

  Widget _buildAccountCard() {
    final user = AppUser.info;
    final name = user?.displayName ?? 'Utilisateur';
    final email = user?.email ?? '';
    final photoUrl = user?.photoUrl;

    return _buildCard(
      child: Column(
        children: [
          // ── En-tête profil ──
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage:
                    photoUrl != null && photoUrl.isNotEmpty
                        ? NetworkImage(photoUrl)
                        : null,
                child: photoUrl == null || photoUrl.isEmpty
                    ? Icon(Icons.person, size: 24, color: _gold)
                    : null,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color: _onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: TextStyle(
                          color: _subtle,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 1.5.h),
          Divider(height: 1, color: _outline.withValues(alpha: 0.2)),
          SizedBox(height: 0.5.h),

          // ── Déconnexion ──
          _buildSettingRow(
            icon: Icons.logout_rounded,
            label: 'settings.logout'.tr,
            subtitle: 'settings.logout_desc'.tr,
            iconColor: _gold,
            textColor: _onSurface,
            subtitleColor: _subtle,
            trailing: Icon(Icons.chevron_right, color: _subtle, size: 20),
            onTap: () => _confirmLogout(),
          ),

          Divider(height: 1, color: _outline.withValues(alpha: 0.2)),

          // ── Suppression du compte ──
          _buildSettingRow(
            icon: Icons.delete_forever_rounded,
            label: 'settings.delete_account'.tr,
            subtitle: 'settings.delete_account_desc'.tr,
            iconColor: _error,
            textColor: _error,
            subtitleColor: _error.withValues(alpha: 0.7),
            trailing: Icon(Icons.chevron_right, color: _error.withValues(alpha: 0.5), size: 20),
            onTap: () => _confirmDeleteAccount(),
          ),
        ],
      ),
    );
  }

  /// Supprime toutes les données utilisateur en cascade dans Firestore.
  Future<void> _deleteUserCascade(String googleId) async {

    // ── 1. Posts de l'utilisateur ──
    final userPosts = await FirestoreCollectionsService.posts
        .where('userData.googleId', isEqualTo: googleId)
        .get();
    for (final doc in userPosts.docs) {
      await doc.reference.delete();
    }

    // ── 2. Messages (envoyés ou reçus) ──
    final sentMessages = await FirestoreCollectionsService.sms
        .where('senderId', isEqualTo: googleId)
        .get();
    for (final doc in sentMessages.docs) {
      await doc.reference.delete();
    }
    final receivedMessages = await FirestoreCollectionsService.sms
        .where('receiveId', isEqualTo: googleId)
        .get();
    for (final doc in receivedMessages.docs) {
      await doc.reference.delete();
    }

    // ── 3. Notifications ──
    final notifs = await FirestoreCollectionsService.notif
        .where('receiveId', isEqualTo: googleId)
        .get();
    for (final doc in notifs.docs) {
      await doc.reference.delete();
    }

    // ── 4. Retirer l'utilisateur des listes d'abonnés (allfollow) ──
    final usersWithFollower = await FirestoreCollectionsService.users
        .where('allfollow', arrayContains: googleId)
        .get();
    for (final doc in usersWithFollower.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final followers = List<String>.from(data['allfollow'] ?? []);
      followers.remove(googleId);
      await doc.reference.update({
        'allfollow': followers,
        'followersCount': followers.length,
      });
    }

    // ── 5. Retirer les likes de l'utilisateur sur tous les posts ──
    final likedPosts = await FirestoreCollectionsService.posts
        .where('postData.allike', arrayContains: googleId)
        .get();
    for (final doc in likedPosts.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final allike = List<String>.from(data['postData']?['allike'] ?? []);
      allike.remove(googleId);
      await doc.reference.update({
        'postData.allike': allike,
        'postData.likes': allike.length,
      });
    }

    // ── 6. Supprimer le document utilisateur ──
    final userQuery = await FirestoreCollectionsService.users
        .where('googleId', isEqualTo: googleId)
        .limit(1)
        .get();
    if (userQuery.docs.isNotEmpty) {
      await userQuery.docs.first.reference.delete();
    }
  }

  /// Confirme et exécute la déconnexion.
  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: _gold, size: 22),
            SizedBox(width: 2.w),
            Text('auth.logout'.tr, style: TextStyle(color: _onSurface, fontSize: 18)),
          ],
        ),
        content: Text(
          'auth.logout_confirm'.tr,
          style: TextStyle(color: _subtle, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('app.cancel'.tr, style: TextStyle(color: _subtle)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('auth.logout_title'.tr, style: TextStyle(color: _gold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      authController.getdelete();
    }
  }

  /// ── Première étape : ré-authentification ──
  /// Vérifie l'identité avant d'autoriser la suppression.
  Future<bool> _showReAuthDialog() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Get.snackbar('app.error'.tr, 'settings.no_user'.tr);
      return false;
    }

    // Déterminer le fournisseur d'authentification
    final isGoogleUser = user.providerData
        .any((info) => info.providerId == 'google.com');

    if (isGoogleUser) {
      // ── Ré-authentification Google (via l'instance partagée d'AuthController) ──
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: _gold, size: 22),
              SizedBox(width: 2.w),
              Expanded(
                child: Text('auth.verification'.tr,
                    style: TextStyle(color: _onSurface, fontSize: 16)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pour supprimer votre compte, confirmez votre identité avec Google.',
                style: TextStyle(color: _subtle, fontSize: 14),
              ),
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      // Utiliser une nouvelle instance GoogleSignIn – sur mobile,
                      // si l'utilisateur est déjà connecté, le sélecteur de compte
                      // ne s'affiche pas et la session existante est réutilisée.
                      final googleSignIn = GoogleSignIn();
                      final googleAccount = await googleSignIn.signIn();
                      if (googleAccount == null) return;

                      final auth = await googleAccount.authentication;
                      final credential = GoogleAuthProvider.credential(
                        idToken: auth.idToken,
                        accessToken: auth.accessToken,
                      );
                      await user.reauthenticateWithCredential(credential);

                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } on FirebaseAuthException catch (e) {
                      if (ctx.mounted) {
                        Get.snackbar(
                          'auth.verification_failed'.tr,
                          e.message ?? 'settings.verify_error'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: _error,
                          colorText: Colors.white,
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        Get.snackbar(
                          'app.error'.tr,
                          'settings.verify_error'.tr,
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: _error,
                          colorText: Colors.white,
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
                  label: Text('auth.continue_google'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text('app.cancel'.tr, style: TextStyle(color: _subtle)),
            ),
          ],
        ),
      );
      return result ?? false;
    } else {
      // ── Ré-authentification Email/Mot de passe ──
      final emailController = TextEditingController(text: user.email ?? '');
      final passwordController = TextEditingController();

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          bool obscure = true;
          return StatefulBuilder(
            builder: (context, setDialogState) => AlertDialog(
              backgroundColor: _surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.lock_outline, color: _gold, size: 22),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text('auth.verification'.tr,
                        style: TextStyle(color: _onSurface, fontSize: 16)),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'auth.verify_password'.tr,
                    style: TextStyle(color: _subtle, fontSize: 14),
                  ),
                  SizedBox(height: 1.5.h),
                  TextField(
                    controller: emailController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'auth.email_label'.tr,
                      labelStyle: TextStyle(color: _subtle),
                      filled: true,
                      fillColor: _subtle.withValues(alpha: 0.08),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: TextStyle(color: _onSurface, fontSize: 14),
                  ),
                  SizedBox(height: 1.h),
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'auth.password_label'.tr,
                      labelStyle: TextStyle(color: _subtle),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _outline),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: _subtle,
                          size: 20,
                        ),
                        onPressed: () =>
                            setDialogState(() => obscure = !obscure),
                      ),
                    ),
                    style: TextStyle(color: _onSurface, fontSize: 14),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text('app.cancel'.tr, style: TextStyle(color: _subtle)),
                ),
                TextButton(
                  onPressed: () async {
                    if (passwordController.text.isEmpty) return;
                    try {
                      final credential = EmailAuthProvider.credential(
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                      );
                      await user.reauthenticateWithCredential(credential);
                      if (ctx.mounted) Navigator.pop(ctx, true);
                    } on FirebaseAuthException catch (e) {
                      Get.snackbar(
                        'auth.verification_failed'.tr,
                        e.message ?? 'auth.wrong_password'.tr,
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: _error,
                        colorText: Colors.white,
                      );
                    }
                  },
                  child: Text('auth.verify'.tr, style: TextStyle(color: _gold)),
                ),
              ],
            ),
          );
        },
      );

      emailController.dispose();
      passwordController.dispose();
      return result ?? false;
    }
  }

  /// ── Deuxième étape : confirmation finale ──
  Future<bool> _showDeleteConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: _error, size: 22),
            SizedBox(width: 2.w),
            Text('settings.delete_account'.tr,
                style: TextStyle(color: _onSurface, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'settings.delete_irreversible'.tr,
              style: TextStyle(color: _subtle, fontSize: 14),
            ),
            SizedBox(height: 1.5.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: _error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'settings.delete_confirm'.tr,
                style: TextStyle(
                  color: _error,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('app.cancel'.tr, style: TextStyle(color: _subtle)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('app.delete'.tr, style: TextStyle(color: _error)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Confirme et exécute la suppression du compte avec vérification d'identité.
  Future<void> _confirmDeleteAccount() async {
    // Étape 1 : Ré-authentification
    final reAuthOk = await _showReAuthDialog();
    if (!reAuthOk || !mounted) return;

    // Étape 2 : Confirmation finale
    final confirm = await _showDeleteConfirmationDialog();
    if (!confirm || !mounted) return;

    // Étape 3 : Cascade de suppression
    try {
      Get.dialog(
        const Center(child: CircularProgressIndicator()),
        barrierDismissible: false,
      );

      final googleId = AppUser.info?.googleId;
      if (googleId != null) {
        await _deleteUserCascade(googleId);
      }

      authController.getdelete();
    } catch (e) {
      if (mounted) Get.back();
      Get.snackbar(
        'app.error'.tr,
        'settings.delete_error'.tr + '$e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: _error,
        colorText: Colors.white,
      );
    }
  }

  // ═══════════════════════════════════════════════
  //  À PROPOS
  // ═══════════════════════════════════════════════

  Widget _buildAboutCard() {
    return _buildCard(
      child: Column(
        children: [
          _buildSettingRow(
            icon: Icons.info_outline,
            label: 'settings.version'.tr,
            subtitle: '1.0.0',
            iconColor: _gold,
            textColor: _onSurface,
            subtitleColor: _subtle,
          ),
          Divider(height: 1, color: _outline.withValues(alpha: 0.2)),
          _buildSettingRow(
            icon: Icons.description_outlined,
            label: 'settings.open_source'.tr,
            subtitle: 'settings.open_source_desc'.tr,
            iconColor: _gold,
            textColor: _onSurface,
            subtitleColor: _subtle,
            trailing: Icon(Icons.chevron_right, color: _subtle, size: 20),
            onTap: () => showLicensePage(
              context: context,
              applicationName: 'Kongossa',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2026 Kongossa',
            ),
          ),
        ],
      ),
    );
  }
}
