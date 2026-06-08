import '../../../core/mock/mock_store.dart';
import '../../../core/network/api_client.dart';
import '../domain/ride.dart';

abstract class RideRepository {
  Future<List<Ride>> listByBike(String bikeId);
  Future<Ride> add(Ride ride);
  Future<void> delete(String rideId);
}

class HttpRideRepository implements RideRepository {
  HttpRideRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<Ride>> listByBike(String bikeId) async {
    final json = await _client.get('/bikes/$bikeId/rides');
    final data = (json['data'] as List?) ?? const [];
    return data
        .map((e) => Ride.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<Ride> add(Ride ride) async {
    final json =
        await _client.post('/bikes/${ride.bikeId}/rides', body: ride.toJson());
    return Ride.fromJson(json);
  }

  @override
  Future<void> delete(String rideId) => _client.delete('/rides/$rideId');
}

class MockRideRepository implements RideRepository {
  final MockStore _store = MockStore.instance;

  @override
  Future<List<Ride>> listByBike(String bikeId) async {
    await _tick();
    final list = _store.rides.where((r) => r.bikeId == bikeId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<Ride> add(Ride ride) async {
    await _tick();
    final created = ride.id.isEmpty
        ? Ride(
            id: _store.nextId('ride'),
            bikeId: ride.bikeId,
            title: ride.title,
            date: ride.date,
            distanceKm: ride.distanceKm,
            durationMinutes: ride.durationMinutes,
            source: ride.source,
            notes: ride.notes,
          )
        : ride;
    _store.rides.add(created);
    return created;
  }

  @override
  Future<void> delete(String rideId) async {
    await _tick();
    _store.rides.removeWhere((r) => r.id == rideId);
  }

  Future<void> _tick() =>
      Future<void>.delayed(const Duration(milliseconds: 250));
}
