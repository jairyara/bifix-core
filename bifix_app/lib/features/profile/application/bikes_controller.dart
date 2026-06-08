import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/bike.dart';

/// Loads and mutates the user's bikes.
class BikesController extends AsyncNotifier<List<Bike>> {
  @override
  Future<List<Bike>> build() async {
    return ref.watch(bikeRepositoryProvider).list();
  }

  Future<Bike> add(Bike bike) async {
    final repo = ref.read(bikeRepositoryProvider);
    final created = await repo.add(bike);
    state = AsyncValue.data([...?state.valueOrNull, created]);
    return created;
  }

  Future<void> edit(Bike bike) async {
    final repo = ref.read(bikeRepositoryProvider);
    final updated = await repo.update(bike);
    final list = [...?state.valueOrNull];
    final i = list.indexWhere((b) => b.id == updated.id);
    if (i >= 0) list[i] = updated;
    state = AsyncValue.data(list);
  }

  Future<void> delete(String bikeId) async {
    final repo = ref.read(bikeRepositoryProvider);
    await repo.delete(bikeId);
    final list = [...?state.valueOrNull]..removeWhere((b) => b.id == bikeId);
    state = AsyncValue.data(list);
  }
}

final bikesControllerProvider =
    AsyncNotifierProvider<BikesController, List<Bike>>(BikesController.new);

/// Currently selected bike id (null = use the first available bike).
final selectedBikeIdProvider = StateProvider<String?>((ref) => null);

/// Resolves the selected bike, falling back to the first one.
final selectedBikeProvider = Provider<Bike?>((ref) {
  final bikes = ref.watch(bikesControllerProvider).valueOrNull ?? const [];
  if (bikes.isEmpty) return null;
  final id = ref.watch(selectedBikeIdProvider);
  if (id == null) return bikes.first;
  return bikes.firstWhere((b) => b.id == id, orElse: () => bikes.first);
});
