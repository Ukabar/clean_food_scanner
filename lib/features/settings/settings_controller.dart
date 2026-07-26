import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/local_storage.dart';

class AppSettings {
  const AppSettings({required this.themeMode, required this.locale});

  final ThemeMode themeMode;
  final Locale locale;
}

class SettingsController extends Notifier<AppSettings> {
  final _storage = LocalStorage.instance;

  @override
  AppSettings build() {
    return AppSettings(
      themeMode: _themeModeFromString(_storage.themeMode),
      locale: Locale(_storage.languageCode),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AppSettings(themeMode: mode, locale: state.locale);
    await _storage.setThemeMode(mode.name);
  }

  Future<void> setLocale(Locale locale) async {
    state = AppSettings(themeMode: state.themeMode, locale: locale);
    await _storage.setLanguageCode(locale.languageCode);
  }

  ThemeMode _themeModeFromString(String value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
