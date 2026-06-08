// Maintenance domain for an e-bike.
//
// A [MaintenanceTask] describes a recurring job and how often it should be
// done — by distance (intervalKm) and/or by time (intervalDays).
// A [MaintenanceRecord] is a completed job at a given odometer/date.
// The pure [buildRecommendations] engine compares the two to tell the user
// what is due.

/// Catalog of recurring maintenance jobs for an e-bike.
class MaintenanceTask {
  const MaintenanceTask({
    required this.id,
    required this.name,
    required this.description,
    this.intervalKm,
    this.intervalDays,
  });

  final String id;
  final String name;
  final String description;

  /// Recommended distance between jobs (km). Null = not distance-based.
  final double? intervalKm;

  /// Recommended time between jobs (days). Null = not time-based.
  final int? intervalDays;

  factory MaintenanceTask.fromJson(Map<String, dynamic> json) {
    return MaintenanceTask(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      intervalKm: (json['intervalKm'] as num?)?.toDouble(),
      intervalDays: (json['intervalDays'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        if (intervalKm != null) 'intervalKm': intervalKm,
        if (intervalDays != null) 'intervalDays': intervalDays,
      };
}

/// A completed maintenance job.
class MaintenanceRecord {
  const MaintenanceRecord({
    required this.id,
    required this.bikeId,
    required this.taskId,
    required this.date,
    required this.odometerKm,
    this.notes,
    this.costCents,
  });

  final String id;
  final String bikeId;
  final String taskId;
  final DateTime date;

  /// Bike total distance at the moment the job was done.
  final double odometerKm;
  final String? notes;
  final int? costCents;

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'].toString(),
      bikeId: json['bikeId'].toString(),
      taskId: json['taskId'].toString(),
      date: DateTime.tryParse(json['date'].toString()) ?? DateTime.now(),
      odometerKm: (json['odometerKm'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String?,
      costCents: (json['costCents'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'bikeId': bikeId,
        'taskId': taskId,
        'date': date.toIso8601String(),
        'odometerKm': odometerKm,
        if (notes != null) 'notes': notes,
        if (costCents != null) 'costCents': costCents,
      };
}

/// Urgency of a recommendation.
enum MaintenanceStatus { ok, dueSoon, overdue }

/// A computed recommendation for one task on one bike.
class MaintenanceRecommendation {
  const MaintenanceRecommendation({
    required this.task,
    required this.status,
    required this.reason,
    this.lastRecord,
    this.kmUntilDue,
    this.daysUntilDue,
    required this.progress,
  });

  final MaintenanceTask task;
  final MaintenanceStatus status;

  /// Short human-readable explanation, e.g. "Vencido hace 40 km".
  final String reason;
  final MaintenanceRecord? lastRecord;

  /// Remaining km until due (negative = overdue). Null if not distance-based.
  final double? kmUntilDue;

  /// Remaining days until due (negative = overdue). Null if not time-based.
  final int? daysUntilDue;

  /// 0..1 progress through the current interval (1 = exactly due).
  final double progress;
}

/// Pure recommendation engine. Given the task catalog, the records done on a
/// bike, the bike's current odometer and the current date, returns one
/// recommendation per task, sorted most-urgent first.
List<MaintenanceRecommendation> buildRecommendations({
  required List<MaintenanceTask> tasks,
  required List<MaintenanceRecord> records,
  required double currentOdometerKm,
  required DateTime now,
}) {
  final result = <MaintenanceRecommendation>[];

  for (final task in tasks) {
    // Most recent record for this task, if any.
    MaintenanceRecord? last;
    for (final r in records) {
      if (r.taskId != task.id) continue;
      if (last == null || r.date.isAfter(last.date)) last = r;
    }

    double? kmUntilDue;
    int? daysUntilDue;
    double progress = 0;

    if (task.intervalKm != null && task.intervalKm! > 0) {
      final baseKm = last?.odometerKm ?? 0;
      final kmSince = (currentOdometerKm - baseKm).clamp(0, double.infinity);
      kmUntilDue = task.intervalKm! - kmSince;
      progress = kmSince / task.intervalKm!;
    }

    if (task.intervalDays != null && task.intervalDays! > 0) {
      final baseDate = last?.date;
      if (baseDate != null) {
        final daysSince = now.difference(baseDate).inDays;
        final d = task.intervalDays! - daysSince;
        daysUntilDue = d;
        final p = daysSince / task.intervalDays!;
        // When both km and time apply, the more advanced one wins.
        if (p > progress) progress = p;
      } else {
        // Never done and time-based: treat as due now.
        daysUntilDue = 0;
        if (progress < 1) progress = 1;
      }
    }

    final status = _statusFor(progress, hasRecord: last != null);
    final reason = _reasonFor(
      status: status,
      kmUntilDue: kmUntilDue,
      daysUntilDue: daysUntilDue,
      hasRecord: last != null,
    );

    result.add(
      MaintenanceRecommendation(
        task: task,
        status: status,
        reason: reason,
        lastRecord: last,
        kmUntilDue: kmUntilDue,
        daysUntilDue: daysUntilDue,
        progress: progress.clamp(0, 2).toDouble(),
      ),
    );
  }

  // Most urgent first: overdue > dueSoon > ok, then by progress desc.
  result.sort((a, b) {
    final byStatus = b.status.index.compareTo(a.status.index);
    if (byStatus != 0) return byStatus;
    return b.progress.compareTo(a.progress);
  });
  return result;
}

MaintenanceStatus _statusFor(double progress, {required bool hasRecord}) {
  if (progress >= 1.0) return MaintenanceStatus.overdue;
  if (progress >= 0.8) return MaintenanceStatus.dueSoon;
  return MaintenanceStatus.ok;
}

String _reasonFor({
  required MaintenanceStatus status,
  required double? kmUntilDue,
  required int? daysUntilDue,
  required bool hasRecord,
}) {
  if (!hasRecord && status != MaintenanceStatus.ok) {
    return 'Sin registro previo. Te recomendamos revisarlo.';
  }

  // Prefer the dimension that is most overdue / closest to due.
  final parts = <String>[];
  if (kmUntilDue != null) {
    if (kmUntilDue < 0) {
      parts.add('vencido hace ${kmUntilDue.abs().round()} km');
    } else {
      parts.add('faltan ${kmUntilDue.round()} km');
    }
  }
  if (daysUntilDue != null) {
    if (daysUntilDue < 0) {
      parts.add('vencido hace ${daysUntilDue.abs()} días');
    } else {
      parts.add('faltan $daysUntilDue días');
    }
  }
  if (parts.isEmpty) return 'Al día';
  final body = parts.join(' · ');
  return body[0].toUpperCase() + body.substring(1);
}

/// Default seed catalog used by the mock backend. The real API will own this.
const List<MaintenanceTask> defaultMaintenanceTasks = [
  MaintenanceTask(
    id: 'chain-lube',
    name: 'Lubricar cadena',
    description: 'Limpia y lubrica la cadena para reducir el desgaste.',
    intervalKm: 200,
  ),
  MaintenanceTask(
    id: 'brakes',
    name: 'Revisar frenos',
    description: 'Inspecciona pastillas y ajusta el frenado.',
    intervalKm: 1000,
    intervalDays: 180,
  ),
  MaintenanceTask(
    id: 'tires',
    name: 'Neumáticos y presión',
    description: 'Revisa presión, desgaste y posibles pinchazos.',
    intervalKm: 750,
  ),
  MaintenanceTask(
    id: 'battery',
    name: 'Chequeo de batería',
    description: 'Verifica salud, contactos y ciclo de carga.',
    intervalDays: 90,
  ),
  MaintenanceTask(
    id: 'drivetrain',
    name: 'Transmisión',
    description: 'Revisa piñones, desviador y tensión de cambios.',
    intervalKm: 2000,
  ),
  MaintenanceTask(
    id: 'general',
    name: 'Revisión general',
    description: 'Tornillería, luces y ajuste integral.',
    intervalKm: 1500,
    intervalDays: 365,
  ),
];
