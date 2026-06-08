import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_settings.dart';

/// Holds the initialized [SharedPreferences]. Overridden in `main()` so the
/// settings (and theme) are available synchronously on first build — no flash.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override sharedPreferencesProvider in main'),
);

/// Reads and persists [AppSettings] via [SharedPreferences].
class SettingsController extends Notifier<AppSettings> {
  static const _kThemeMode = 'settings.themeMode';
  static const _kMaintenanceReminders = 'settings.maintenanceReminders';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final themeIdx = _prefs.getInt(_kThemeMode);
    return AppSettings(
      themeMode: (themeIdx != null && themeIdx >= 0 && themeIdx < ThemeMode.values.length)
          ? ThemeMode.values[themeIdx]
          : ThemeMode.system,
      maintenanceReminders: _prefs.getBool(_kMaintenanceReminders) ?? true,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setInt(_kThemeMode, mode.index);
  }

  Future<void> setMaintenanceReminders(bool enabled) async {
    state = state.copyWith(maintenanceReminders: enabled);
    await _prefs.setBool(_kMaintenanceReminders, enabled);
  }
}

final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
