import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/format.dart';
import '../application/rides_controller.dart';
import '../domain/ride.dart';

/// Opens the modal sheet to register a (v1: estimated) ride for a bike.
///
/// The tracking assistant reuses this passing [initialDurationMinutes] and
/// [forcedSource] (RideSource.tracked) so a "tracked" ride flows through the
/// same confirmation step until real GPS lands in phase 2.
Future<void> showAddRideSheet(
  BuildContext context, {
  required String bikeId,
  int? initialDurationMinutes,
  String? initialTitle,
  RideSource? forcedSource,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _AddRideSheet(
        bikeId: bikeId,
        initialDurationMinutes: initialDurationMinutes,
        initialTitle: initialTitle,
        forcedSource: forcedSource,
      ),
    ),
  );
}

class _AddRideSheet extends ConsumerStatefulWidget {
  const _AddRideSheet({
    required this.bikeId,
    this.initialDurationMinutes,
    this.initialTitle,
    this.forcedSource,
  });
  final String bikeId;
  final int? initialDurationMinutes;
  final String? initialTitle;
  final RideSource? forcedSource;

  @override
  ConsumerState<_AddRideSheet> createState() => _AddRideSheetState();
}

class _AddRideSheetState extends ConsumerState<_AddRideSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _title =
      TextEditingController(text: widget.initialTitle ?? '');
  final _distance = TextEditingController();
  late final _duration = TextEditingController(
      text: widget.initialDurationMinutes?.toString() ?? '');
  final _speed = TextEditingController(text: '20');
  DateTime _date = DateTime.now();
  // When the assistant hands us a duration, start in estimate-by-time mode.
  late bool _estimateByTime = widget.initialDurationMinutes != null;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _distance.dispose();
    _duration.dispose();
    _speed.dispose();
    super.dispose();
  }

  double? get _estimatedKm {
    if (!_estimateByTime) return null;
    final mins = int.tryParse(_duration.text) ?? 0;
    final speed = double.tryParse(_speed.text.replaceAll(',', '.')) ?? 0;
    return estimateDistanceKm(durationMinutes: mins, avgSpeedKmh: speed);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final double km;
    int? duration;
    if (_estimateByTime) {
      km = _estimatedKm ?? 0;
      duration = int.tryParse(_duration.text);
      if (km <= 0) {
        _snack('Revisa tiempo y velocidad para estimar la distancia.');
        return;
      }
    } else {
      km = double.tryParse(_distance.text.replaceAll(',', '.')) ?? 0;
    }

    setState(() => _saving = true);
    try {
      await ref.read(ridesControllerProvider(widget.bikeId).notifier).add(
            Ride(
              id: '',
              bikeId: widget.bikeId,
              title: _title.text.trim().isEmpty
                  ? 'Recorrido'
                  : _title.text.trim(),
              date: _date,
              distanceKm: km,
              durationMinutes: duration,
              source: widget.forcedSource ??
                  (_estimateByTime
                      ? RideSource.estimated
                      : RideSource.manual),
            ),
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Nuevo recorrido',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título (ej. Casa → Trabajo)',
                prefixIcon: Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('Fecha'),
              subtitle: Text(Fmt.date(_date)),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: 4),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Distancia'), icon: Icon(Icons.straighten)),
                ButtonSegment(value: true, label: Text('Estimar'), icon: Icon(Icons.timer_outlined)),
              ],
              selected: {_estimateByTime},
              onSelectionChanged: (s) =>
                  setState(() => _estimateByTime = s.first),
            ),
            const SizedBox(height: 16),
            if (!_estimateByTime)
              TextFormField(
                controller: _distance,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Distancia (km)',
                  prefixIcon: Icon(Icons.straighten),
                ),
                validator: (v) {
                  if (_estimateByTime) return null;
                  final n = double.tryParse((v ?? '').replaceAll(',', '.'));
                  if (n == null || n <= 0) return 'Ingresa una distancia válida';
                  return null;
                },
              )
            else ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _duration,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Tiempo (min)',
                        prefixIcon: Icon(Icons.timer_outlined),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _speed,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Vel. (km/h)',
                        prefixIcon: Icon(Icons.speed),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_graph),
                    const SizedBox(width: 8),
                    Text('Distancia estimada: '
                        '${Fmt.km(_estimatedKm ?? 0)}'),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Text('Guardar recorrido'),
            ),
          ],
        ),
      ),
    );
  }
}
