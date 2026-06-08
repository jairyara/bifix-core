import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/async_views.dart';
import '../../auth/application/auth_controller.dart';
import '../../maintenance/application/maintenance_controller.dart';
import '../../maintenance/domain/maintenance.dart';
import '../../maintenance/presentation/widgets/status_style.dart';
import '../../preferences/application/preferences_controller.dart';
import '../../preferences/domain/riding_mode.dart';
import '../../preferences/presentation/mode_framing.dart';
import '../../profile/application/bikes_controller.dart';
import '../../rides/application/rides_controller.dart';
import '../../rides/presentation/add_ride_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final bikesAsync = ref.watch(bikesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hola, ${user?.name.split(' ').first ?? ''}',
                style: Theme.of(context).textTheme.titleLarge),
            Text('Tu e-bike de un vistazo',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
      body: bikesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(bikesControllerProvider),
        ),
        data: (bikes) {
          if (bikes.isEmpty) {
            return EmptyView(
              icon: Icons.pedal_bike,
              title: 'Aún no tienes una bici',
              subtitle: 'Agrega tu bicicleta eléctrica para llevar el control '
                  'de recorridos y mantenimientos.',
              action: FilledButton.icon(
                onPressed: () => context.push(Routes.addBike),
                icon: const Icon(Icons.add),
                label: const Text('Agregar bici'),
              ),
            );
          }
          return const _DashboardBody();
        },
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bike = ref.watch(selectedBikeProvider);
    if (bike == null) return const SizedBox.shrink();
    final odometer = ref.watch(odometerProvider(bike.id));
    final mode = ref.watch(ridingModeProvider);
    final recs = ref.watch(recommendationsProvider(bike.id)).valueOrNull ?? const [];
    final rides = ref.watch(ridesControllerProvider(bike.id)).valueOrNull ?? const [];
    final attention =
        recs.where((r) => r.status != MaintenanceStatus.ok).toList();

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ridesControllerProvider(bike.id));
        ref.invalidate(recordsControllerProvider(bike.id));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _BikeOdometerCard(
              bikeName: bike.name,
              model: bike.displayModel,
              odometer: odometer,
              mode: mode),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Mantenimiento',
            actionLabel: 'Ver todo',
            onAction: () => context.go(Routes.maintenance),
          ),
          if (attention.isEmpty)
            const _OkBanner()
          else
            ...attention.take(3).map((r) => _RecommendationTile(rec: r)),
          const SizedBox(height: 16),
          _SectionHeader(
            title: 'Recorridos recientes',
            actionLabel: 'Ver todo',
            onAction: () => context.go(Routes.rides),
          ),
          if (rides.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('Sin recorridos aún.'),
            )
          else
            ...rides.take(3).map((r) => _RideRow(
                  title: r.title,
                  date: r.date,
                  distanceKm: r.distanceKm,
                )),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => showAddRideSheet(context, bikeId: bike.id),
            icon: const Icon(Icons.add_road),
            label: const Text('Registrar recorrido'),
          ),
        ],
      ),
    );
  }
}

class _BikeOdometerCard extends StatelessWidget {
  const _BikeOdometerCard({
    required this.bikeName,
    required this.model,
    required this.odometer,
    required this.mode,
  });
  final String bikeName;
  final String model;
  final double odometer;
  final RidingMode? mode;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: scheme.primary,
                  child: Icon(Icons.pedal_bike,
                      color: scheme.onPrimary, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bikeName,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold)),
                      if (model.isNotEmpty)
                        Text(model,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: scheme.onPrimaryContainer)),
                      const SizedBox(height: 8),
                      Text('Odómetro estimado',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onPrimaryContainer)),
                      Text(Fmt.km(odometer),
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            if (mode != null) ...[
              const SizedBox(height: 12),
              _ModeBadge(mode: mode!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small pill showing the active mode framing (privacy / assistant).
class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.mode});
  final RidingMode mode;

  @override
  Widget build(BuildContext context) {
    final framing = ModeFraming.of(mode);
    final accent = framing.accentFor(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(framing.icon, size: 16, color: accent),
          const SizedBox(width: 6),
          Text(
            mode == RidingMode.estimation
                ? 'Modo privacidad'
                : 'Modo asistente',
            style: TextStyle(
                color: accent, fontWeight: FontWeight.w600, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.rec});
  final MaintenanceRecommendation rec;

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.of(rec.status);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: style.color.withValues(alpha: 0.15),
          child: Icon(iconForTask(rec.task.id), color: style.color),
        ),
        title: Text(rec.task.name),
        subtitle: Text(rec.reason),
        trailing: Icon(style.icon, color: style.color),
        onTap: () => context.go(Routes.maintenance),
      ),
    );
  }
}

class _RideRow extends StatelessWidget {
  const _RideRow({
    required this.title,
    required this.date,
    required this.distanceKm,
  });
  final String title;
  final DateTime date;
  final double distanceKm;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.route)),
        title: Text(title),
        subtitle: Text(Fmt.ago(date)),
        trailing: Text(Fmt.km(distanceKm),
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _OkBanner extends StatelessWidget {
  const _OkBanner();

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.of(MaintenanceStatus.ok);
    return Card(
      child: ListTile(
        leading: Icon(Icons.check_circle, color: style.color),
        title: const Text('Todo al día'),
        subtitle: const Text('No hay mantenimientos pendientes.'),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(title,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}
