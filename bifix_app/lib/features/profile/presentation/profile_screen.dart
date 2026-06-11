import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/async_views.dart';
import '../../auth/application/auth_controller.dart';
import '../../maintenance/application/maintenance_controller.dart';
import '../../preferences/application/preferences_controller.dart';
import '../../preferences/domain/riding_mode.dart';
import '../../preferences/presentation/mode_framing.dart';
import '../application/bikes_controller.dart';
import '../domain/bike.dart';
import 'edit_profile_sheet.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    final bikesAsync = ref.watch(bikesControllerProvider);
    final selectedId = ref.watch(selectedBikeProvider)?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ajustes',
            onPressed: () => context.push(Routes.settings),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Cerrar sesión'),
                  content: const Text('¿Seguro que quieres salir?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancelar')),
                    FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Salir')),
                  ],
                ),
              );
              if (confirm == true) {
                await ref.read(authControllerProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (user != null) _UserCard(name: user.name, email: user.email,
              phone: user.phone, since: user.createdAt),
          const SizedBox(height: 8),
          const _ModeSection(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mis bicicletas',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () => context.push(Routes.addBike),
                icon: const Icon(Icons.add),
                label: const Text('Agregar'),
              ),
            ],
          ),
          bikesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: LoadingView(),
            ),
            error: (e, _) => ErrorView(error: e),
            data: (bikes) {
              if (bikes.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Aún no has agregado bicicletas.'),
                );
              }
              return Column(
                children: [
                  for (final bike in bikes)
                    _BikeTile(
                      bike: bike,
                      selected: bike.id == selectedId,
                      onSelect: () => ref
                          .read(selectedBikeIdProvider.notifier)
                          .state = bike.id,
                      onEdit: () => context.push('${Routes.editBike}?id=${bike.id}'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _UserCard extends ConsumerWidget {
  const _UserCard({
    required this.name,
    required this.email,
    required this.phone,
    required this.since,
  });
  final String name;
  final String email;
  final String? phone;
  final DateTime? since;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: scheme.onPrimaryContainer),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(email,
                          style: Theme.of(context).textTheme.bodyMedium),
                      if (phone != null && phone!.isNotEmpty)
                        Text(phone!,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => showEditProfileSheet(context),
                ),
              ],
            ),
            if (since != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const Icon(Icons.verified_user_outlined, size: 18),
                  const SizedBox(width: 8),
                  Text('Miembro desde ${Fmt.date(since!)}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BikeTile extends ConsumerWidget {
  const _BikeTile({
    required this.bike,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
  });
  final Bike bike;
  final bool selected;
  final VoidCallback onSelect;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final odometer = ref.watch(odometerProvider(bike.id));
    final due = ref.watch(dueCountProvider(bike.id));
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 1.8 : 1,
        ),
      ),
      child: ListTile(
        onTap: onSelect,
        leading: CircleAvatar(
          backgroundColor:
              selected ? scheme.primary : scheme.surfaceContainerHighest,
          child: Icon(Icons.pedal_bike,
              color: selected ? scheme.onPrimary : scheme.onSurfaceVariant),
        ),
        title: Text(bike.name,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text([
          if (bike.displayModel.isNotEmpty) bike.displayModel,
          Fmt.km(odometer),
          if (due > 0) '$due pendiente${due == 1 ? '' : 's'}',
        ].join(' · ')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Icon(Icons.check_circle, color: scheme.primary, size: 20),
            IconButton(
                icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
          ],
        ),
      ),
    );
  }
}

/// Shows the active riding mode (privacy / assistant) with actions to change it
/// or, in estimation mode, adjust the daily average.
class _ModeSection extends ConsumerWidget {
  const _ModeSection();

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
    final mode = ref.watch(ridingModeProvider);
    if (mode == null) return const SizedBox.shrink();
    final framing = ModeFraming.of(mode);
    final accent = framing.accentFor(Theme.of(context).brightness);
    final profile =
        ref.watch(preferencesControllerProvider).valueOrNull?.dailyProfile;

    String? detail;
    if (mode == RidingMode.estimation && profile != null) {
      final days = (profile.activeWeekdays.toList()..sort())
          .map((d) => _dayLabels[d])
          .join(' ');
      detail = 'Promedio ${Fmt.km(profile.dailyKm)}/día · $days';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: accent.withValues(alpha: 0.15),
                  child: Icon(framing.icon, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Modo de seguimiento',
                          style: Theme.of(context).textTheme.bodySmall),
                      Text('${framing.title} · ${framing.badge}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      if (detail != null)
                        Text(detail,
                            style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              overflowAlignment: OverflowBarAlignment.end,
              spacing: 8,
              overflowSpacing: 4,
              children: [
                if (mode == RidingMode.estimation)
                  TextButton.icon(
                    onPressed: () =>
                        context.push(Routes.onboardingEstimation),
                    icon: const Icon(Icons.tune, size: 18),
                    label: const Text('Editar promedio'),
                  ),
                TextButton.icon(
                  onPressed: () => context.push(Routes.onboardingMode),
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Cambiar modo'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
