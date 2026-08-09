import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  final Map<String, String> _strings = {};

  Future<void> load() async {
    final languageCode = locale.languageCode;
    final path = 'assets/i18n/$languageCode.json';
    try {
      final jsonString = await rootBundle.loadString(path);
      final map = json.decode(jsonString) as Map<String, dynamic>;
      _strings.addAll(map.map((key, value) => MapEntry(key, value.toString())));
    } catch (_) {
      final fallbackString = await rootBundle.loadString('assets/i18n/en.json');
      final map = json.decode(fallbackString) as Map<String, dynamic>;
      _strings.addAll(map.map((key, value) => MapEntry(key, value.toString())));
    }
  }

  String translate(String key) {
    return _strings[key] ?? key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'es', 'pt'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final localizations = AppLocalizations(locale);
    await localizations.load();
    return localizations;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}
