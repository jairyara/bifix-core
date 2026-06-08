import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../preferences/application/preferences_controller.dart';
import '../../preferences/domain/riding_mode.dart';
import '../../preferences/presentation/mode_framing.dart';

/// Step shown after picking the estimation (privacy) mode: configure the typical
/// daily distance and which weekdays the user rides.
class DailyProfileSetupScreen extends ConsumerStatefulWidget {
  const DailyProfileSetupScreen({super.key});

  @override
  ConsumerState<DailyProfileSetupScreen> createState() =>
      _DailyProfileSetupScreenState();
}

class _DailyProfileSetupScreenState
    extends ConsumerState<DailyProfileSetupScreen> {
  final _dailyKm = TextEditingController(text: '12');
  // 1=Mon .. 7=Sun. Default Mon–Fri.
  final Set<int> _days = {1, 2, 3, 4, 5};
  bool _saving = false;

  static const _labels = {
    1: 'L',
    2: 'M',
    3: 'M',
    4: 'J',
    5: 'V',
    6: 'S',
    7: 'D',
  };

  @override
  void initState() {
    super.initState();
    final existing =
        ref.read(preferencesControllerProvider).valueOrNull?.dailyProfile;
    if (existing != null) {
      _dailyKm.text = existing.dailyKm.toStringAsFixed(0);
      _days
        ..clear()
        ..addAll(existing.activeWeekdays);
    }
  }

  @override
  void dispose() {
    _dailyKm.dispose();
    super.dispose();
  }

  double get _weeklyKm {
    final km = double.tryParse(_dailyKm.text.replaceAll(',', '.')) ?? 0;
    return km * _days.length;
  }

  Future<void> _save() async {
    final km = double.tryParse(_dailyKm.text.replaceAll(',', '.')) ?? 0;
    if (km <= 0) {
      _snack('Ingresa un promedio de km mayor a 0.');
      return;
    }
    if (_days.isEmpty) {
      _snack('Elige al menos un día.');
      return;
    }
    setState(() => _saving = true);
    try {
      final existing =
          ref.read(preferencesControllerProvider).valueOrNull?.dailyProfile;
      final profile = DailyEstimateProfile(
        dailyKm: km,
        activeWeekdays: Set.of(_days),
        // Keep the original accrual start when adjusting; otherwise start today.
        since: existing?.since ?? DateTime.now(),
      );
      await ref
          .read(preferencesControllerProvider.notifier)
          .completeEstimationOnboarding(profile);
      if (mounted) context.go(Routes.home);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final framing = ModeFraming.of(RidingMode.estimation);
    final accent = framing.accentFor(Theme.of(context).brightness);
    return Scaffold(
      appBar: AppBar(title: const Text('Tu rutina')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Row(
              children: [
                Icon(framing.icon, color: accent),
                const SizedBox(width: 8),
                Text(framing.badge,
                    style: TextStyle(
                        color: accent, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            Text('¿Cuánto sueles rodar por día?',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'Con esto estimamos tu odómetro sin rastrear tu ubicación. '
              'Siempre podrás sumar salidas puntuales.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _dailyKm,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Promedio diario (km)',
                prefixIcon: Icon(Icons.straighten),
              ),
            ),
            const SizedBox(height: 20),
            Text('Días que ruedas',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                for (final entry in _labels.entries)
                  FilterChip(
                    label: Text(entry.value),
                    selected: _days.contains(entry.key),
                    onSelected: (sel) => setState(() {
                      if (sel) {
                        _days.add(entry.key);
                      } else {
                        _days.remove(entry.key);
                      }
                    }),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_month, color: accent),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Estimado: ~${_weeklyKm.toStringAsFixed(0)} km por semana '
                      '(${_days.length} día${_days.length == 1 ? '' : 's'})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Text('Empezar'),
            ),
          ],
        ),
      ),
    );
  }
}
