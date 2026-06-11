/// How the user feeds the odometer that drives maintenance recommendations.
///
/// The choice is framed as a benefit in the UI:
///  - [estimation] → privacy ("no rastreamos tu ubicación").
///  - [tracking]   → assistant ("Vikla registra por ti").
enum RidingMode { estimation, tracking }

extension RidingModeX on RidingMode {
  String get apiValue => name;

  static RidingMode? tryParse(String? value) {
    switch (value) {
      case 'estimation':
        return RidingMode.estimation;
      case 'tracking':
        return RidingMode.tracking;
      default:
        return null;
    }
  }
}

/// Recurring estimate for the privacy mode: a typical daily distance ridden on
/// a set of weekdays. The odometer accrues automatically from [since].
class DailyEstimateProfile {
  const DailyEstimateProfile({
    required this.dailyKm,
    required this.activeWeekdays,
    required this.since,
  });

  /// Average distance ridden on an active day.
  final double dailyKm;

  /// Weekdays the user rides, using [DateTime.weekday] (1=Mon .. 7=Sun).
  final Set<int> activeWeekdays;

  /// Date from which the recurring accrual starts counting.
  final DateTime since;

  DailyEstimateProfile copyWith({
    double? dailyKm,
    Set<int>? activeWeekdays,
    DateTime? since,
  }) {
    return DailyEstimateProfile(
      dailyKm: dailyKm ?? this.dailyKm,
      activeWeekdays: activeWeekdays ?? this.activeWeekdays,
      since: since ?? this.since,
    );
  }

  factory DailyEstimateProfile.fromJson(Map<String, dynamic> json) {
    final days = (json['active_weekdays'] as List?)
            ?.map((e) => (e as num).toInt())
            .toSet() ??
        {1, 2, 3, 4, 5};
    return DailyEstimateProfile(
      dailyKm: (json['daily_km'] as num?)?.toDouble() ?? 0,
      activeWeekdays: days,
      since: DateTime.tryParse(json['since']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'daily_km': dailyKm,
        'active_weekdays': activeWeekdays.toList()..sort(),
        'since': since.toIso8601String(),
      };
}

/// Per-user preferences. A null [ridingMode] means the user has not completed
/// onboarding yet.
class UserPreferences {
  const UserPreferences({this.ridingMode, this.dailyProfile});

  final RidingMode? ridingMode;
  final DailyEstimateProfile? dailyProfile;

  bool get needsOnboarding => ridingMode == null;

  UserPreferences copyWith({
    RidingMode? ridingMode,
    DailyEstimateProfile? dailyProfile,
  }) {
    return UserPreferences(
      ridingMode: ridingMode ?? this.ridingMode,
      dailyProfile: dailyProfile ?? this.dailyProfile,
    );
  }

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      ridingMode: RidingModeX.tryParse(json['riding_mode'] as String?),
      dailyProfile: json['daily_profile'] is Map<String, dynamic>
          ? DailyEstimateProfile.fromJson(
              json['daily_profile'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'riding_mode': ridingMode?.apiValue,
        'daily_profile': dailyProfile?.toJson(),
      };

  static const empty = UserPreferences();
}

/// Pure helper: distance accrued by a recurring daily profile between
/// [profile.since] and [now], counting only whole active days.
///
/// Today is excluded (only completed days count) to avoid over-estimating.
double recurringAccrualKm(DailyEstimateProfile profile, DateTime now) {
  if (profile.dailyKm <= 0 || profile.activeWeekdays.isEmpty) return 0;
  final start = DateTime(profile.since.year, profile.since.month,
      profile.since.day);
  final today = DateTime(now.year, now.month, now.day);
  if (!today.isAfter(start)) return 0;

  var activeDays = 0;
  for (var day = start;
      day.isBefore(today);
      day = day.add(const Duration(days: 1))) {
    if (profile.activeWeekdays.contains(day.weekday)) activeDays++;
  }
  return activeDays * profile.dailyKm;
}
