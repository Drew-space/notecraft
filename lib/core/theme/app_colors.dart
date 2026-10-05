// lib/core/theme/app_colors.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One place for every color that changes between light and dark mode.
/// Use it anywhere with:  final c = context.colors;
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.scaffold,
    required this.surface,
    required this.fieldBg,
    required this.searchBg,
    required this.chipBg,
    required this.border,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.textFaint,
    required this.accent,
    required this.onAccent,
    required this.dotInactive,
    required this.link,
  });

  final Color scaffold; // screen background
  final Color surface; // cards, sheets, dialogs, drawer
  final Color fieldBg; // text fields inside sheets, round buttons
  final Color searchBg; // search bar
  final Color chipBg; // small badges, selected drawer row
  final Color border;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color textFaint;
  final Color accent; // main button / selected chip background
  final Color onAccent; // content drawn on top of accent
  final Color dotInactive;
  final Color link;

  static const AppColors light = AppColors(
    scaffold: Color(0xFFF6F6F6),
    surface: Color(0xFFFFFFFF),
    fieldBg: Color(0xFFF6F6F6),
    searchBg: Color(0xFFEFEFEF),
    chipBg: Color(0xFFF2F2F2),
    border: Color(0xFFE5E5E5),
    divider: Color(0xFFEFEFEF),
    textPrimary: Color(0xFF1A1A1A),
    textSecondary: Color(0xFF4B5563),
    textMuted: Color(0xFF8C8B8E),
    textFaint: Color(0xFF9CA3AF),
    accent: Color(0xFF1A1A1A),
    onAccent: Color(0xFFFFFFFF),
    dotInactive: Color(0xFFD9D9D9),
    link: Color(0xFF2563EB),
  );

  static const AppColors dark = AppColors(
    scaffold: Color(0xFF121212),
    surface: Color(0xFF1E1E1E),
    fieldBg: Color(0xFF2A2A2A),
    searchBg: Color(0xFF262626),
    chipBg: Color(0xFF2A2A2A),
    border: Color(0xFF363636),
    divider: Color(0xFF2C2C2C),
    textPrimary: Color(0xFFF2F2F2),
    textSecondary: Color(0xFFB4B7BD),
    textMuted: Color(0xFF8E9097),
    textFaint: Color(0xFF6B7280),
    accent: Color(0xFFF2F2F2),
    onAccent: Color(0xFF1A1A1A),
    dotInactive: Color(0xFF3A3A3A),
    link: Color(0xFF60A5FA),
  );

  @override
  AppColors copyWith({
    Color? scaffold,
    Color? surface,
    Color? fieldBg,
    Color? searchBg,
    Color? chipBg,
    Color? border,
    Color? divider,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? textFaint,
    Color? accent,
    Color? onAccent,
    Color? dotInactive,
    Color? link,
  }) {
    return AppColors(
      scaffold: scaffold ?? this.scaffold,
      surface: surface ?? this.surface,
      fieldBg: fieldBg ?? this.fieldBg,
      searchBg: searchBg ?? this.searchBg,
      chipBg: chipBg ?? this.chipBg,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      textFaint: textFaint ?? this.textFaint,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
      dotInactive: dotInactive ?? this.dotInactive,
      link: link ?? this.link,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      scaffold: l(scaffold, other.scaffold),
      surface: l(surface, other.surface),
      fieldBg: l(fieldBg, other.fieldBg),
      searchBg: l(searchBg, other.searchBg),
      chipBg: l(chipBg, other.chipBg),
      border: l(border, other.border),
      divider: l(divider, other.divider),
      textPrimary: l(textPrimary, other.textPrimary),
      textSecondary: l(textSecondary, other.textSecondary),
      textMuted: l(textMuted, other.textMuted),
      textFaint: l(textFaint, other.textFaint),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      dotInactive: l(dotInactive, other.dotInactive),
      link: l(link, other.link),
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}

/// Status bar and navigation bar style for the current mode.
/// Dark icons on a light screen, light icons on a dark screen.
SystemUiOverlayStyle overlayStyleFor(Brightness brightness, AppColors colors) {
  final isDark = brightness == Brightness.dark;
  final iconBrightness = isDark ? Brightness.light : Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: iconBrightness,
    // iOS uses the opposite meaning: it describes the screen behind the bar
    statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarColor: colors.scaffold,
    systemNavigationBarIconBrightness: iconBrightness,
    systemNavigationBarDividerColor: Colors.transparent,
    systemNavigationBarContrastEnforced: false,
  );
}
