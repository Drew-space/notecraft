// lib/viewmodels/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String _kThemeKey = 'themeMode';

/// Holds the current theme mode and remembers it between app launches.
/// The app starts in light mode until the user taps the toggle.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final saved =
        Hive.box('settings').get(_kThemeKey, defaultValue: 'light') as String;
    return saved == 'dark' ? ThemeMode.dark : ThemeMode.light;
  }

  void setMode(ThemeMode mode) {
    state = mode;
    Hive.box(
      'settings',
    ).put(_kThemeKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);
