import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../preferences/application/preferences_controller.dart';
import '../../preferences/domain/riding_mode.dart';
import '../../profile/application/bikes_controller.dart';
import '../../rides/application/rides_controller.dart';
import '../domain/maintenance.dart';

/// Catalog of maintenance tasks (shared across bikes).
final maintenanceTasksProvider =
    FutureProvider<List<MaintenanceTask>>((ref) async {
  return ref.watch(maintenanceRepositoryProvider).tasks();
});

/// Maintenance records for one bike, keyed by bikeId.
class RecordsController
    extends FamilyAsyncNotifier<List<MaintenanceRecord>, String> {
  @override
  Future<List<MaintenanceRecord>> build(String bikeId) async {
    return ref.watch(maintenanceRepositoryProvider).recordsByBike(bikeId);
  }

  Future<void> add(MaintenanceRecord record) async {
    final repo = ref.read(maintenanceRepositoryProvider);
    final created = await repo.addRecord(record);
    final list = [created, ...?state.valueOrNull]
      ..sort((a, b) => b.date.compareTo(a.date));
    state = AsyncValue.data(list);
  }

  Future<void> delete(String recordId) async {
    final repo = ref.read(maintenanceRepositoryProvider);
    await repo.deleteRecord(recordId);
    final list = [...?state.valueOrNull]..removeWhere((r) => r.id == recordId);
    state = AsyncValue.data(list);
  }
}

final recordsControllerProvider = AsyncNotifierProvider.family<RecordsController,
    List<MaintenanceRecord>, String>(RecordsController.new);

/// Current odometer for a bike, computed client-side so it stays reactive.
///
///   odometer = baseline
///            + sum(rides)                         // manual / estimated / tracked
///            + recurring accrual (estimation mode only)
///
/// In estimation (privacy) mode the recurring daily profile accrues distance
/// automatically; in tracking (assistant) mode only logged rides count.
final odometerProvider = Provider.family<double, String>((ref, bikeId) {
  final bikes = ref.watch(bikesControllerProvider).valueOrNull ?? const [];
  final matches = bikes.where((b) => b.id == bikeId);
  final baseline = matches.isEmpty ? 0.0 : matches.first.baselineKm;
  final ridden = ref.watch(ridesDistanceProvider(bikeId));

  var accrual = 0.0;
  final prefs = ref.watch(preferencesControllerProvider).valueOrNull;
  if (prefs?.ridingMode == RidingMode.estimation &&
      prefs?.dailyProfile != null) {
    accrual = recurringAccrualKm(prefs!.dailyProfile!, DateTime.now());
  }

  return baseline + ridden + accrual;
});

/// The computed maintenance recommendations for a bike, most urgent first.
final recommendationsProvider =
    Provider.family<AsyncValue<List<MaintenanceRecommendation>>, String>(
        (ref, bikeId) {
  final tasksAsync = ref.watch(maintenanceTasksProvider);
  final recordsAsync = ref.watch(recordsControllerProvider(bikeId));
  final odometer = ref.watch(odometerProvider(bikeId));

  // Combine the two async sources; surface loading/error if either is pending.
  return tasksAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (tasks) => recordsAsync.when(
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
      data: (records) => AsyncValue.data(
        buildRecommendations(
          tasks: tasks,
          records: records,
          currentOdometerKm: odometer,
          now: DateTime.now(),
        ),
      ),
    ),
  );
});

/// Count of recommendations that need attention (dueSoon or overdue).
final dueCountProvider = Provider.family<int, String>((ref, bikeId) {
  final recs = ref.watch(recommendationsProvider(bikeId)).valueOrNull ?? const [];
  return recs.where((r) => r.status != MaintenanceStatus.ok).length;
});
