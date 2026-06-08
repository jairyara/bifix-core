import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/notifications/maintenance_reminders.dart';
import 'core/notifications/notification_service.dart';
import 'core/router/app_router.dart';
import 'core/settings/settings_controller.dart';
import 'core/theme/app_theme.dart';

/// Root widget. Wires the router, theme, Spanish localization, and keeps local
/// maintenance reminders in sync with the recommendation engine.
class ViklaApp extends ConsumerStatefulWidget {
  const ViklaApp({super.key});

  @override
  ConsumerState<ViklaApp> createState() => _ViklaAppState();
}

class _ViklaAppState extends ConsumerState<ViklaApp> {
  bool _askedPermission = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode =
        ref.watch(settingsControllerProvider.select((s) => s.themeMode));

    // Whenever the set of due/overdue maintenance changes, (re)schedule the
    // local reminder. We prime the OS permission the first time there's
    // actually something to remind about.
    ref.listen<List<MaintenanceReminder>>(pendingMaintenanceProvider,
        (prev, next) async {
      final service = ref.read(notificationServiceProvider);
      if (next.isNotEmpty && !_askedPermission) {
        _askedPermission = true;
        await service.requestPermission();
      }
      await service.syncMaintenanceReminders(next);
    });

    return MaterialApp.router(
      title: 'Vikla',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      locale: const Locale('es'),
      supportedLocales: const [Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
