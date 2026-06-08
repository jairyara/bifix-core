import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/async_views.dart';
import '../../preferences/application/preferences_controller.dart';
import '../../preferences/domain/riding_mode.dart';
import '../../preferences/presentation/mode_framing.dart';
import '../../profile/application/bikes_controller.dart';
import '../application/rides_controller.dart';
import '../domain/ride.dart';
import 'add_ride_sheet.dart';

class RidesScreen extends ConsumerWidget {
  const RidesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bike = ref.watch(selectedBikeProvider);
    final mode = ref.watch(ridingModeProvider);
    final isTracking = mode == RidingMode.tracking;

    return Scaffold(
      appBar: AppBar(title: const Text('Recorridos')),
      floatingActionButton: bike == null
          ? null
          : isTracking
              ? FloatingActionButton.extended(
                  backgroundColor: ModeFraming.of(RidingMode.tracking).accent,
                  foregroundColor: Colors.white,
                  onPressed: () => context.push(Routes.tracking),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Iniciar'),
                )
              : FloatingActionButton.extended(
                  onPressed: () => showAddRideSheet(context, bikeId: bike.id),
                  icon: const Icon(Icons.add),
                  label: const Text('Salida'),
                ),
      body: bike == null
          ? const EmptyView(
              icon: Icons.pedal_bike,
              title: 'Agrega una bici primero',
              subtitle: 'Necesitas una bicicleta para registrar recorridos.',
            )
          : Column(
              children: [
                if (mode != null) _ModeBanner(mode: mode),
                Expanded(child: _RidesList(bikeId: bike.id)),
              ],
            ),
    );
  }
}

/// Header that reflects the active mode: privacy summary or assistant prompt.
class _ModeBanner extends ConsumerWidget {
  const _ModeBanner({required this.mode});
  final RidingMode mode;

  static const _dayLabels = {
    1: 'L',
    2: 'M',
    3: 'M',
    4: 'J',
    5: 'V',
    6: 'S',
    7: 'D',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final framing = ModeFraming.of(mode);
    String subtitle;
    if (mode == RidingMode.estimation) {
      final profile =
          ref.watch(preferencesControllerProvider).valueOrNull?.dailyProfile;
      if (profile != null) {
        final days = (profile.activeWeekdays.toList()..sort())
            .map((d) => _dayLabels[d])
            .join(' ');
        subtitle =
            'Promedio ${Fmt.km(profile.dailyKm)}/día · $days · suma salidas puntuales';
      } else {
        subtitle = 'Configura tu promedio diario en tu perfil';
      }
    } else {
      subtitle = 'Pulsa Iniciar para que el asistente registre tu recorrido';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: framing.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: framing.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(framing.icon, color: framing.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(framing.badge,
                    style: TextStyle(
                        color: framing.accent, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RidesList extends ConsumerWidget {
  const _RidesList({required this.bikeId});
  final String bikeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ridesAsync = ref.watch(ridesControllerProvider(bikeId));
    final total = ref.watch(ridesDistanceProvider(bikeId));

    return ridesAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(
        error: e,
        onRetry: () => ref.invalidate(ridesControllerProvider(bikeId)),
      ),
      data: (rides) {
        if (rides.isEmpty) {
          return EmptyView(
            icon: Icons.route,
            title: 'Sin recorridos',
            subtitle:
                'Registra tu primer recorrido. En esta versión la distancia es '
                'estimada (manual o por tiempo × velocidad).',
            action: FilledButton.icon(
              onPressed: () => showAddRideSheet(context, bikeId: bikeId),
              icon: const Icon(Icons.add),
              label: const Text('Registrar recorrido'),
            ),
          );
        }
        return Column(
          children: [
            _TotalsBar(count: rides.length, totalKm: total),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(ridesControllerProvider(bikeId)),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: rides.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _RideCard(
                    ride: rides[i],
                    onDelete: () => ref
                        .read(ridesControllerProvider(bikeId).notifier)
                        .delete(rides[i].id),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TotalsBar extends StatelessWidget {
  const _TotalsBar({required this.count, required this.totalKm});
  final int count;
  final double totalKm;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Metric(label: 'Recorridos', value: '$count'),
          Container(width: 1, height: 32, color: scheme.outlineVariant),
          _Metric(label: 'Distancia total', value: Fmt.km(totalKm)),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _RideCard extends StatelessWidget {
  const _RideCard({required this.ride, required this.onDelete});
  final Ride ride;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final speed = ride.avgSpeedKmh;
    return Dismissible(
      key: ValueKey(ride.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            child: Icon(ride.source == RideSource.estimated
                ? Icons.auto_graph
                : Icons.route),
          ),
          title: Text(ride.title),
          subtitle: Text([
            Fmt.date(ride.date),
            if (ride.durationMinutes != null) '${ride.durationMinutes} min',
            if (speed != null) '${speed.toStringAsFixed(0)} km/h',
          ].join(' · ')),
          trailing: Text(Fmt.km(ride.distanceKm),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
