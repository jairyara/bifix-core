import 'package:flutter_test/flutter_test.dart';

import 'package:vikla/features/maintenance/domain/maintenance.dart';
import 'package:vikla/features/preferences/domain/riding_mode.dart';
import 'package:vikla/features/rides/domain/ride.dart';

void main() {
  group('estimateDistanceKm', () {
    test('30 min at 20 km/h ≈ 10 km', () {
      expect(estimateDistanceKm(durationMinutes: 30, avgSpeedKmh: 20), 10.0);
    });

    test('invalid input returns 0', () {
      expect(estimateDistanceKm(durationMinutes: 0, avgSpeedKmh: 20), 0);
    });
  });

  group('buildRecommendations', () {
    final now = DateTime(2026, 6, 6);

    test('flags a distance-based task as overdue past its interval', () {
      const task = MaintenanceTask(
        id: 'chain-lube',
        name: 'Lubricar cadena',
        description: '',
        intervalKm: 200,
      );
      final recs = buildRecommendations(
        tasks: [task],
        records: const [],
        currentOdometerKm: 250, // past the 200 km interval
        now: now,
      );
      expect(recs.single.status, MaintenanceStatus.overdue);
    });

    test('uses the last record as the baseline', () {
      const task = MaintenanceTask(
        id: 'brakes',
        name: 'Frenos',
        description: '',
        intervalKm: 1000,
      );
      final records = [
        MaintenanceRecord(
          id: 'r1',
          bikeId: 'b1',
          taskId: 'brakes',
          date: now.subtract(const Duration(days: 10)),
          odometerKm: 500,
        ),
      ];
      final recs = buildRecommendations(
        tasks: [task],
        records: records,
        currentOdometerKm: 600, // only 100 km since last → ok
        now: now,
      );
      expect(recs.single.status, MaintenanceStatus.ok);
    });
  });

  group('recurringAccrualKm', () {
    final since = DateTime(2026, 6, 1);

    test('counts every whole day when all weekdays are active', () {
      final profile = DailyEstimateProfile(
        dailyKm: 10,
        activeWeekdays: const {1, 2, 3, 4, 5, 6, 7},
        since: since,
      );
      // 7 completed days (Jun 1..Jun 7), today excluded.
      final accrual = recurringAccrualKm(profile, DateTime(2026, 6, 8));
      expect(accrual, 70);
    });

    test('excludes inactive weekdays', () {
      // Only the weekday of `since`; over 14 days it occurs exactly twice.
      final profile = DailyEstimateProfile(
        dailyKm: 10,
        activeWeekdays: {since.weekday},
        since: since,
      );
      final accrual =
          recurringAccrualKm(profile, since.add(const Duration(days: 14)));
      expect(accrual, 20);
    });

    test('returns 0 before any full day passes', () {
      final profile = DailyEstimateProfile(
        dailyKm: 10,
        activeWeekdays: const {1, 2, 3, 4, 5, 6, 7},
        since: since,
      );
      expect(recurringAccrualKm(profile, since), 0);
    });

    test('returns 0 with no active days', () {
      final profile = DailyEstimateProfile(
        dailyKm: 10,
        activeWeekdays: const {},
        since: since,
      );
      expect(recurringAccrualKm(profile, DateTime(2026, 7, 1)), 0);
    });
  });
}
