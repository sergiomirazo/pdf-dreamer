import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/theme/app_theme.dart';

class SettingsController extends ChangeNotifier {
  SettingsController() {
    _loadSettings();
  }

  Locale _locale = const Locale('es');
  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = AppTheme.accent;

  Locale get locale => _locale;
  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;

  static const _localeKey = 'app_locale';
  static const _themeKey = 'app_theme_mode';
  static const _accentKey = 'app_accent_color';

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final localeCode = prefs.getString(_localeKey);
    if (localeCode != null && ['en', 'es', 'pt'].contains(localeCode)) {
      _locale = Locale(localeCode);
    }
    final themeMode = prefs.getString(_themeKey);
    if (themeMode != null) {
      switch (themeMode) {
        case 'light':
          _themeMode = ThemeMode.light;
        case 'dark':
          _themeMode = ThemeMode.dark;
        case 'system':
          _themeMode = ThemeMode.system;
      }
    }
    final savedAccent = prefs.getInt(_accentKey);
    if (savedAccent != null) {
      _accentColor = Color(0xFF000000 | (savedAccent & 0xFFFFFF));
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
      case ThemeMode.dark:
        value = 'dark';
      case ThemeMode.system:
        value = 'system';
    }
    await prefs.setString(_themeKey, value);
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = Color(0xFF000000 | (color.toARGB32() & 0xFFFFFF));
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentKey, _accentColor.toARGB32());
  }
}
