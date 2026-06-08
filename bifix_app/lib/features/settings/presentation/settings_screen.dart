import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/settings/settings_controller.dart';
import '../../auth/application/auth_controller.dart';

/// App preferences: appearance (theme), notifications, and about.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsControllerProvider);
    final controller = ref.read(settingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const _SectionTitle('Apariencia'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tema',
                      style: Theme.of(context)
                          .textTheme
                          .titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.system, label: Text('Sistema')),
                      ButtonSegment(
                          value: ThemeMode.light, label: Text('Claro')),
                      ButtonSegment(
                          value: ThemeMode.dark, label: Text('Oscuro')),
                    ],
                    selected: {settings.themeMode},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => controller.setThemeMode(s.first),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Notificaciones'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Recordatorios de mantenimiento'),
                  subtitle: const Text(
                      'Te avisamos cuando una tarea esté próxima o vencida.'),
                  value: settings.maintenanceReminders,
                  onChanged: (v) async {
                    await controller.setMaintenanceReminders(v);
                    if (!v) return;
                    final granted = await ref
                        .read(notificationServiceProvider)
                        .requestPermission();
                    if (!granted && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            'Activa las notificaciones en los ajustes del sistema para recibir avisos.'),
                      ));
                    }
                  },
                ),
                if (settings.maintenanceReminders) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Probar notificación'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final service = ref.read(notificationServiceProvider);
                      await service.requestPermission();
                      await service.showNow('Vikla',
                          'Así se verán tus recordatorios de mantenimiento.');
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Cuenta'),
          Card(
            child: ListTile(
              leading: Icon(Icons.delete_forever_outlined,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Eliminar cuenta',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              subtitle: const Text('Borra tu cuenta y tus datos de forma permanente.'),
              onTap: () => _confirmDelete(context, ref),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionTitle('Acerca de'),
          const Card(
            child: ListTile(
              leading: Icon(Icons.pedal_bike),
              title: Text('Vikla'),
              subtitle: Text('Mantenimiento de bicicletas eléctricas'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar cuenta'),
        content: const Text(
            'Esta acción es permanente. Se borrará tu cuenta junto con tus '
            'bicicletas, recorridos y mantenimientos. ¿Quieres continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    // On success the auth session becomes null and the router redirects to
    // the login screen automatically.
    await ref.read(authControllerProvider.notifier).deleteAccount();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}
