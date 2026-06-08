import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/maintenance/application/maintenance_controller.dart';
import '../../features/maintenance/domain/maintenance.dart';
import '../../features/profile/application/bikes_controller.dart';
import '../settings/settings_controller.dart';
import 'notification_service.dart';

/// Flattens every bike's due/overdue recommendations into a single list of
/// [MaintenanceReminder]s. Returns empty when reminders are disabled, so the
/// coordinator simply cancels everything.
final pendingMaintenanceProvider = Provider<List<MaintenanceReminder>>((ref) {
  final enabled = ref.watch(
      settingsControllerProvider.select((s) => s.maintenanceReminders));
  if (!enabled) return const [];

  final bikes = ref.watch(bikesControllerProvider).valueOrNull ?? const [];
  final reminders = <MaintenanceReminder>[];
  for (final bike in bikes) {
    final recs =
        ref.watch(recommendationsProvider(bike.id)).valueOrNull ?? const [];
    for (final r in recs) {
      if (r.status == MaintenanceStatus.ok) continue;
      reminders.add(MaintenanceReminder(
        bikeName: bike.name,
        taskName: r.task.name,
        overdue: r.status == MaintenanceStatus.overdue,
      ));
    }
  }
  // Overdue first.
  reminders.sort((a, b) => (b.overdue ? 1 : 0) - (a.overdue ? 1 : 0));
  return reminders;
});
