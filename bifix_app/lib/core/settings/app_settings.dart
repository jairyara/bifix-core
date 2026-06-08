import 'package:flutter/material.dart';

/// User-facing app preferences persisted locally (not tied to the account).
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.maintenanceReminders = true,
  });

  /// Light / dark / follow-system. The brand requires both light and dark.
  final ThemeMode themeMode;

  /// Whether to schedule local notifications for due/overdue maintenance.
  final bool maintenanceReminders;

  AppSettings copyWith({ThemeMode? themeMode, bool? maintenanceReminders}) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      maintenanceReminders: maintenanceReminders ?? this.maintenanceReminders,
    );
  }
}
