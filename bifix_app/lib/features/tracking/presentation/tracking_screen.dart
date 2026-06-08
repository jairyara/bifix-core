import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_views.dart';
import '../../preferences/domain/riding_mode.dart';
import '../../preferences/presentation/mode_framing.dart';
import '../../profile/application/bikes_controller.dart';
import '../../rides/domain/ride.dart';
import '../../rides/presentation/add_ride_sheet.dart';

/// Tracking assistant shell. Start/stop with a live timer; on stop the elapsed
/// time is handed to the ride sheet (marked [RideSource.tracked]) to confirm the
/// distance. Real GPS capture lands in phase 2 — this keeps the UX and data flow.
class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  bool _running = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _running = true;
      _elapsed = Duration.zero;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed += const Duration(seconds: 1));
    });
  }

  Future<void> _stop(String bikeId) async {
    _timer?.cancel();
    setState(() => _running = false);
    final minutes = (_elapsed.inSeconds / 60).ceil().clamp(1, 100000);
    await showAddRideSheet(
      context,
      bikeId: bikeId,
      initialDurationMinutes: minutes,
      initialTitle: 'Recorrido con asistente',
      forcedSource: RideSource.tracked,
    );
    if (mounted) setState(() => _elapsed = Duration.zero);
  }

  String get _clock {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = _elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final bike = ref.watch(selectedBikeProvider);
    final framing = ModeFraming.of(RidingMode.tracking);

    return Scaffold(
      appBar: AppBar(title: const Text('Asistente')),
      body: bike == null
          ? const EmptyView(
              icon: Icons.pedal_bike,
              title: 'Agrega una bici primero',
              subtitle: 'El asistente registra recorridos sobre tu bicicleta.',
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: framing.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(framing.icon, color: framing.accent, size: 18),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(framing.badge,
                                style: TextStyle(
                                    color: framing.accent,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _PulseRing(
                      active: _running,
                      accent: framing.accent,
                      child: Text(
                        _clock,
                        style: Theme.of(context)
                            .textTheme
                            .displaySmall
                            ?.copyWith(
                                fontFeatures: const [],
                                fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _running
                          ? 'Grabando tu recorrido…'
                          : 'Listo para acompañarte',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _running
                          ? 'Al detener, confirmas la distancia y se suma a tu odómetro.'
                          : 'Inicia cuando arranques. Vikla lleva el tiempo por ti.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const Spacer(),
                    if (!_running)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: framing.accent),
                        onPressed: _start,
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Iniciar recorrido'),
                      )
                    else
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.error),
                        onPressed: () => _stop(bike.id),
                        icon: const Icon(Icons.stop),
                        label: const Text('Detener'),
                      ),
                    const SizedBox(height: 8),
                    Text(framing.footnote ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Animated ring around the timer while recording.
class _PulseRing extends StatelessWidget {
  const _PulseRing({
    required this.active,
    required this.accent,
    required this.child,
  });
  final bool active;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 200,
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: active ? 0.12 : 0.05),
        border: Border.all(
          color: active ? accent : accent.withValues(alpha: 0.3),
          width: active ? 4 : 2,
        ),
      ),
      child: child,
    );
  }
}
