import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/format.dart';
import '../application/maintenance_controller.dart';
import '../domain/maintenance.dart';

/// Opens a sheet to record that a maintenance [task] was just done on a bike.
/// Pre-fills the odometer with the bike's current estimated distance.
Future<void> showAddRecordSheet(
  BuildContext context, {
  required String bikeId,
  required MaintenanceTask task,
  required double currentOdometerKm,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: _AddRecordSheet(
        bikeId: bikeId,
        task: task,
        currentOdometerKm: currentOdometerKm,
      ),
    ),
  );
}

class _AddRecordSheet extends ConsumerStatefulWidget {
  const _AddRecordSheet({
    required this.bikeId,
    required this.task,
    required this.currentOdometerKm,
  });
  final String bikeId;
  final MaintenanceTask task;
  final double currentOdometerKm;

  @override
  ConsumerState<_AddRecordSheet> createState() => _AddRecordSheetState();
}

class _AddRecordSheetState extends ConsumerState<_AddRecordSheet> {
  late final TextEditingController _odometer = TextEditingController(
      text: widget.currentOdometerKm.toStringAsFixed(0));
  final _notes = TextEditingController();
  final _cost = TextEditingController();
  DateTime _date = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _odometer.dispose();
    _notes.dispose();
    _cost.dispose();
    super.dispose();
  }

  /// Parses the cost field (whole pesos) into cents, or null if empty.
  int? _costCents() {
    final pesos = int.tryParse(_cost.text);
    return (pesos != null && pesos > 0) ? pesos * 100 : null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 730)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(recordsControllerProvider(widget.bikeId).notifier)
          .add(MaintenanceRecord(
            id: '',
            bikeId: widget.bikeId,
            taskId: widget.task.id,
            date: _date,
            odometerKm: double.tryParse(_odometer.text.replaceAll(',', '.')) ??
                widget.currentOdometerKm,
            notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
            costCents: _costCents(),
          ));
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Registrar: ${widget.task.name}',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(widget.task.description,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today_outlined),
            title: const Text('Fecha'),
            subtitle: Text(Fmt.date(_date)),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: _pickDate,
          ),
          TextField(
            controller: _odometer,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Odómetro (km)',
              helperText: 'Distancia de la bici al hacer el mantenimiento',
              prefixIcon: Icon(Icons.speed),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cost,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Costo (opcional)',
              prefixText: '\$ ',
              prefixIcon: Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notas (opcional)',
              prefixIcon: Icon(Icons.notes),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.check),
            label: const Text('Marcar como realizado'),
          ),
        ],
      ),
    );
  }
}
