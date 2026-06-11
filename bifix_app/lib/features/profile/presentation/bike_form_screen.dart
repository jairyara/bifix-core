import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/utils/format.dart';
import '../../catalog/presentation/model_picker_sheet.dart';
import '../application/bikes_controller.dart';
import '../domain/bike.dart';

/// Add or edit a bike. When [bikeId] is null we create a new one.
///
/// When [onboarding] is true this is the first onboarding step ("registro de
/// inicio"): saving advances to the riding-mode step instead of popping.
class BikeFormScreen extends ConsumerStatefulWidget {
  const BikeFormScreen({super.key, this.bikeId, this.onboarding = false});
  final String? bikeId;
  final bool onboarding;

  @override
  ConsumerState<BikeFormScreen> createState() => _BikeFormScreenState();
}

class _BikeFormScreenState extends ConsumerState<BikeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _year = TextEditingController();
  final _battery = TextEditingController();
  final _baseline = TextEditingController(text: '0');
  DateTime? _purchaseDate;
  bool _saving = false;
  bool _initialized = false;

  bool get _isEditing => widget.bikeId != null;

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _model.dispose();
    _year.dispose();
    _battery.dispose();
    _baseline.dispose();
    super.dispose();
  }

  void _prefill(Bike bike) {
    _name.text = bike.name;
    _brand.text = bike.brand ?? '';
    _model.text = bike.model ?? '';
    _year.text = bike.year?.toString() ?? '';
    _battery.text = bike.batteryWh?.toString() ?? '';
    _baseline.text = bike.baselineKm.toStringAsFixed(0);
    _purchaseDate = bike.purchaseDate;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final controller = ref.read(bikesControllerProvider.notifier);
    final data = Bike(
      id: widget.bikeId ?? '',
      name: _name.text.trim(),
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      model: _model.text.trim().isEmpty ? null : _model.text.trim(),
      year: int.tryParse(_year.text),
      batteryWh: int.tryParse(_battery.text),
      baselineKm:
          double.tryParse(_baseline.text.replaceAll(',', '.')) ?? 0,
      purchaseDate: _purchaseDate,
    );
    try {
      if (_isEditing) {
        await controller.edit(data);
      } else {
        final created = await controller.add(data);
        ref.read(selectedBikeIdProvider.notifier).state = created.id;
      }
      if (!mounted) return;
      if (widget.onboarding) {
        // Registro de inicio done → continue to the riding-mode step.
        context.go(Routes.onboardingMode);
      } else {
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar bici'),
        content: const Text(
            'Se borrarán también sus recorridos y mantenimientos. ¿Continuar?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(bikesControllerProvider.notifier).delete(widget.bikeId!);
    ref.read(selectedBikeIdProvider.notifier).state = null;
    if (mounted) Navigator.of(context).pop();
  }

  /// Opens the catalog picker and autocompletes brand/model/year/battery from
  /// the chosen model. Fields stay editable; the odometer is untouched.
  Future<void> _pickFromCatalog() async {
    final model = await showModelPickerSheet(context);
    if (model == null) return;
    setState(() {
      if (model.brand != null) _brand.text = model.brand!.name;
      _model.text = model.name;
      if (model.year != null) _year.text = model.year!.toString();
      if (model.batteryWh != null) _battery.text = model.batteryWh!.toString();
      if (_name.text.trim().isEmpty) _name.text = model.name;
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _purchaseDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    // Prefill once when editing, after bikes are loaded.
    if (_isEditing && !_initialized) {
      final bikes = ref.watch(bikesControllerProvider).valueOrNull ?? const [];
      final match = bikes.where((b) => b.id == widget.bikeId);
      if (match.isNotEmpty) {
        _prefill(match.first);
        _initialized = true;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing
            ? 'Editar bici'
            : widget.onboarding
                ? 'Registra tu bici'
                : 'Agregar bici'),
        automaticallyImplyLeading: !widget.onboarding,
        actions: [
          if (_isEditing)
            IconButton(
                icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    hintText: 'Mi e-bike',
                    prefixIcon: Icon(Icons.pedal_bike),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Ponle un nombre'
                      : null,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickFromCatalog,
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar en catálogo'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'O escribe los datos a mano',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _brand,
                        decoration: const InputDecoration(
                          labelText: 'Marca',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _model,
                        decoration: const InputDecoration(labelText: 'Modelo'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _year,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Año',
                          prefixIcon: Icon(Icons.event),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _battery,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Batería (Wh)',
                          prefixIcon: Icon(Icons.battery_full),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _baseline,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Kilometraje inicial (odómetro)',
                    helperText:
                        'Distancia que ya tenía la bici al registrarla',
                    prefixIcon: Icon(Icons.speed),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Fecha de compra'),
                  subtitle: Text(_purchaseDate == null
                      ? 'Opcional'
                      : Fmt.date(_purchaseDate!)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickDate,
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
                      : Text(_isEditing
                          ? 'Guardar cambios'
                          : widget.onboarding
                              ? 'Continuar'
                              : 'Agregar bici'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
