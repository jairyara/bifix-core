import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/ride.dart';

/// Rides for a single bike, keyed by bikeId via `.family`.
class RidesController extends FamilyAsyncNotifier<List<Ride>, String> {
  @override
  Future<List<Ride>> build(String bikeId) async {
    return ref.watch(rideRepositoryProvider).listByBike(bikeId);
  }

  Future<Ride> add(Ride ride) async {
    final repo = ref.read(rideRepositoryProvider);
    final created = await repo.add(ride);
    final list = [created, ...?state.valueOrNull]
      ..sort((a, b) => b.date.compareTo(a.date));
    state = AsyncValue.data(list);
    return created;
  }

  Future<void> delete(String rideId) async {
    final repo = ref.read(rideRepositoryProvider);
    await repo.delete(rideId);
    final list = [...?state.valueOrNull]..removeWhere((r) => r.id == rideId);
    state = AsyncValue.data(list);
  }
}

final ridesControllerProvider =
    AsyncNotifierProvider.family<RidesController, List<Ride>, String>(
        RidesController.new);

/// Total distance logged for a bike (sum of estimated rides).
final ridesDistanceProvider = Provider.family<double, String>((ref, bikeId) {
  final rides = ref.watch(ridesControllerProvider(bikeId)).valueOrNull ?? const [];
  return rides.fold<double>(0, (sum, r) => sum + r.distanceKm);
});
