import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/catalog.dart';

/// All bike models in the catalog (each with its brand embedded).
final bikeModelsProvider = FutureProvider<List<BikeModel>>((ref) {
  return ref.watch(catalogRepositoryProvider).models();
});

/// All brands in the catalog.
final brandsProvider = FutureProvider<List<Brand>>((ref) {
  return ref.watch(catalogRepositoryProvider).brands();
});
