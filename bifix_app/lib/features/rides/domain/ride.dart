/// How the distance of a ride was obtained.
///  - [estimated]: derived from time × speed.
///  - [manual]: distance typed directly by the user.
///  - [tracked]: captured by the tracking assistant (real GPS arrives in phase 2).
enum RideSource { estimated, manual, tracked }

/// A single trip on a bike. Its [distanceKm] feeds the bike odometer and,
/// therefore, the maintenance recommendations.
class Ride {
  const Ride({
    required this.id,
    required this.bikeId,
    required this.title,
    required this.date,
    required this.distanceKm,
    this.durationMinutes,
    this.source = RideSource.estimated,
    this.notes,
  });

  final String id;
  final String bikeId;
  final String title;
  final DateTime date;
  final double distanceKm;
  final int? durationMinutes;
  final RideSource source;
  final String? notes;

  /// Average speed in km/h, when a duration is available.
  double? get avgSpeedKmh {
    final d = durationMinutes;
    if (d == null || d <= 0) return null;
    return distanceKm / (d / 60.0);
  }

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id'].toString(),
      bikeId: json['bikeId'].toString(),
      title: json['title'] as String? ?? 'Recorrido',
      date: DateTime.tryParse(json['date'].toString()) ?? DateTime.now(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      source: switch (json['source']) {
        'manual' => RideSource.manual,
        'tracked' => RideSource.tracked,
        _ => RideSource.estimated,
      },
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bikeId': bikeId,
        'title': title,
        'date': date.toIso8601String(),
        'distanceKm': distanceKm,
        if (durationMinutes != null) 'durationMinutes': durationMinutes,
        'source': source.name,
        if (notes != null) 'notes': notes,
      };
}

/// Pure helper to estimate ride distance from a duration and average speed.
/// Used by the "estimate" flow when the user doesn't know the exact distance.
double estimateDistanceKm({
  required int durationMinutes,
  required double avgSpeedKmh,
}) {
  if (durationMinutes <= 0 || avgSpeedKmh <= 0) return 0;
  return double.parse(
      (avgSpeedKmh * (durationMinutes / 60.0)).toStringAsFixed(1));
}
