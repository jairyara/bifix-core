import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/format.dart';
import '../../../core/widgets/async_views.dart';
import '../../profile/application/bikes_controller.dart';
import '../application/maintenance_controller.dart';
import '../domain/maintenance.dart';
import 'add_record_sheet.dart';
import 'widgets/status_style.dart';

class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bike = ref.watch(selectedBikeProvider);

    if (bike == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Mantenimiento')),
        body: const EmptyView(
          icon: Icons.pedal_bike,
          title: 'Agrega una bici primero',
          subtitle: 'El mantenimiento se calcula sobre tu bicicleta.',
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mantenimiento'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Recomendaciones'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _RecommendationsTab(bikeId: bike.id),
            _HistoryTab(bikeId: bike.id),
          ],
        ),
      ),
    );
  }
}

class _RecommendationsTab extends ConsumerWidget {
  const _RecommendationsTab({required this.bikeId});
  final String bikeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recsAsync = ref.watch(recommendationsProvider(bikeId));
    final odometer = ref.watch(odometerProvider(bikeId));

    return recsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e),
      data: (recs) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(maintenanceTasksProvider);
          ref.invalidate(recordsControllerProvider(bikeId));
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            for (final rec in recs)
              _RecommendationCard(
                rec: rec,
                onRegister: () => showAddRecordSheet(
                  context,
                  bikeId: bikeId,
                  task: rec.task,
                  currentOdometerKm: odometer,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard({required this.rec, required this.onRegister});
  final MaintenanceRecommendation rec;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final style = StatusStyle.of(rec.status);
    final progress = rec.progress.clamp(0.0, 1.0);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: style.color.withValues(alpha: 0.15),
                  child: Icon(iconForTask(rec.task.id), color: style.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rec.task.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(rec.reason,
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                _StatusChip(style: style),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: style.color.withValues(alpha: 0.15),
                color: style.color,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  rec.lastRecord != null
                      ? 'Último: ${Fmt.ago(rec.lastRecord!.date)} · ${Fmt.km(rec.lastRecord!.odometerKm)}'
                      : 'Sin registro previo',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton.icon(
                  onPressed: onRegister,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Registrar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.style});
  final StatusStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        style.label,
        style: TextStyle(
            color: style.color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _HistoryTab extends ConsumerWidget {
  const _HistoryTab({required this.bikeId});
  final String bikeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(recordsControllerProvider(bikeId));
    final tasks =
        ref.watch(maintenanceTasksProvider).valueOrNull ?? const [];

    String taskName(String id) {
      for (final t in tasks) {
        if (t.id == id) return t.name;
      }
      return 'Mantenimiento';
    }

    return recordsAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => ErrorView(error: e),
      data: (records) {
        if (records.isEmpty) {
          return const EmptyView(
            icon: Icons.history,
            title: 'Sin historial',
            subtitle: 'Cuando registres un mantenimiento aparecerá aquí.',
          );
        }
        final totalCents =
            records.fold<int>(0, (sum, r) => sum + (r.costCents ?? 0));
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(recordsControllerProvider(bikeId)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              if (totalCents > 0) ...[
                Card(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withValues(alpha: 0.5),
                  child: ListTile(
                    leading: const Icon(Icons.payments_outlined),
                    title: const Text('Total invertido'),
                    trailing: Text(
                      Fmt.money(totalCents),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              for (final r in records) ...[
                Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Icon(iconForTask(r.taskId))),
                    title: Text(taskName(r.taskId)),
                    subtitle: Text([
                      Fmt.date(r.date),
                      Fmt.km(r.odometerKm),
                      if (r.costCents != null) Fmt.money(r.costCents!),
                      if (r.notes != null) r.notes!,
                    ].join(' · ')),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => ref
                          .read(recordsControllerProvider(bikeId).notifier)
                          .delete(r.id),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        );
      },
    );
  }
}
