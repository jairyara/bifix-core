import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/async_views.dart';
import '../application/catalog_providers.dart';
import '../domain/catalog.dart';

/// Opens a searchable sheet to pick a bike model from the catalog.
/// Returns the chosen [BikeModel], or null if dismissed.
Future<BikeModel?> showModelPickerSheet(BuildContext context) {
  return showModalBottomSheet<BikeModel>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _ModelPickerSheet(),
  );
}

class _ModelPickerSheet extends ConsumerStatefulWidget {
  const _ModelPickerSheet();

  @override
  ConsumerState<_ModelPickerSheet> createState() => _ModelPickerSheetState();
}

class _ModelPickerSheetState extends ConsumerState<_ModelPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final modelsAsync = ref.watch(bikeModelsProvider);
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: FractionallySizedBox(
        heightFactor: 0.85,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Elige tu modelo',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Autocompleta marca, modelo, año y batería.',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: false,
                    onChanged: (v) => setState(() => _query = v.toLowerCase().trim()),
                    decoration: const InputDecoration(
                      hintText: 'Buscar marca o modelo',
                      prefixIcon: Icon(Icons.search),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: modelsAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(error: e),
                data: (models) {
                  final filtered = _query.isEmpty
                      ? models
                      : models
                          .where((m) => m.searchKey.contains(_query))
                          .toList(growable: false);
                  if (filtered.isEmpty) {
                    return const Center(
                        child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Sin resultados. Puedes escribir los datos a mano.'),
                    ));
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final m = filtered[i];
                      return ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.pedal_bike)),
                        title: Text(m.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text([
                          if (m.year != null) m.year,
                          if (m.batteryWh != null) '${m.batteryWh} Wh',
                          if (m.frameType != null) m.frameType,
                        ].join(' · ')),
                        onTap: () => Navigator.of(context).pop(m),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
