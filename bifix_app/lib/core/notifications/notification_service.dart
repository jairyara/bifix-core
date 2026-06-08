import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

/// One pending maintenance item, flattened across the user's bikes.
class MaintenanceReminder {
  const MaintenanceReminder({
    required this.bikeName,
    required this.taskName,
    required this.overdue,
  });

  final String bikeName;
  final String taskName;

  /// true = overdue (vencido); false = due soon (próximo).
  final bool overdue;
}

/// Thin wrapper around [FlutterLocalNotificationsPlugin] for Vikla's
/// maintenance reminders. The plugin is created and [init]ialized in `main()`.
class NotificationService {
  NotificationService(this._plugin);

  final FlutterLocalNotificationsPlugin _plugin;

  static const _channelId = 'maintenance';
  static const _channelName = 'Mantenimiento';
  static const _channelDesc = 'Recordatorios de mantenimiento de tu bici';
  static const _summaryId = 100;

  Future<void> init() async {
    // Permissions are requested explicitly (see [requestPermission]), not here,
    // so we can prime the user at the right moment.
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          _channelId,
          _channelName,
          description: _channelDesc,
          importance: Importance.high,
        ));
  }

  /// Asks the OS for notification permission. Safe to call repeatedly: the
  /// system only prompts once and afterwards returns the current status.
  Future<bool> requestPermission() async {
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
              alert: true, badge: true, sound: true) ??
          false;
    }
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return false;
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Cancels the previous reminder and, if there are pending items, schedules a
  /// single daily summary at 09:00 (local) until the maintenance is resolved.
  Future<void> syncMaintenanceReminders(
      List<MaintenanceReminder> pending) async {
    await _plugin.cancel(id: _summaryId);
    if (pending.isEmpty) return;

    final hasOverdue = pending.any((p) => p.overdue);
    await _plugin.zonedSchedule(
      id: _summaryId,
      title: hasOverdue ? '⚠️ Mantenimiento vencido' : '🔧 Mantenimiento próximo',
      body: _summaryBody(pending),
      scheduledDate: _next9am(),
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily at 09:00
    );
  }

  /// Fires a notification immediately (used by the "probar" button in Ajustes).
  Future<void> showNow(String title, String body) {
    return _plugin.show(
      id: _summaryId + 1,
      title: title,
      body: body,
      notificationDetails: _details,
    );
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  String _summaryBody(List<MaintenanceReminder> pending) {
    if (pending.length == 1) {
      final p = pending.single;
      return '${p.bikeName}: ${p.taskName} '
          '${p.overdue ? 'está vencido' : 'se acerca'}.';
    }
    final sample = pending.take(2).map((p) => p.taskName).join(', ');
    return '${pending.length} tareas por revisar (p. ej. $sample). '
        'Abre Vikla para verlas.';
  }

  tz.TZDateTime _next9am() {
    final now = tz.TZDateTime.now(tz.local);
    var t = tz.TZDateTime(tz.local, now.year, now.month, now.day, 9);
    if (!t.isAfter(now)) t = t.add(const Duration(days: 1));
    return t;
  }
}

/// Overridden in `main()` with the initialized service.
final notificationServiceProvider = Provider<NotificationService>(
  (ref) =>
      throw UnimplementedError('override notificationServiceProvider in main'),
);
