import '../../../core/mock/mock_store.dart';
import '../../../core/network/api_client.dart';
import '../domain/bike.dart';

abstract class BikeRepository {
  Future<List<Bike>> list();
  Future<Bike> add(Bike bike);
  Future<Bike> update(Bike bike);
  Future<void> delete(String bikeId);

  /// Current odometer (baseline + logged rides) for a bike.
  Future<double> odometer(String bikeId);
}

class HttpBikeRepository implements BikeRepository {
  HttpBikeRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<Bike>> list() async {
    final json = await _client.get('/bikes');
    final data = (json['data'] as List?) ?? const [];
    return data
        .map((e) => Bike.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<Bike> add(Bike bike) async {
    final json = await _client.post('/bikes', body: bike.toJson());
    return Bike.fromJson(json);
  }

  @override
  Future<Bike> update(Bike bike) async {
    final json = await _client.put('/bikes/${bike.id}', body: bike.toJson());
    return Bike.fromJson(json);
  }

  @override
  Future<void> delete(String bikeId) => _client.delete('/bikes/$bikeId');

  @override
  Future<double> odometer(String bikeId) async {
    final json = await _client.get('/bikes/$bikeId/odometer');
    return (json['odometerKm'] as num?)?.toDouble() ?? 0;
  }
}

class MockBikeRepository implements BikeRepository {
  final MockStore _store = MockStore.instance;

  @override
  Future<List<Bike>> list() async {
    await _tick();
    return List.of(_store.bikes);
  }

  @override
  Future<Bike> add(Bike bike) async {
    await _tick();
    final created = bike.id.isEmpty
        ? Bike(
            id: _store.nextId('bike'),
            name: bike.name,
            brand: bike.brand,
            model: bike.model,
            year: bike.year,
            batteryWh: bike.batteryWh,
            baselineKm: bike.baselineKm,
            purchaseDate: bike.purchaseDate,
          )
        : bike;
    _store.bikes.add(created);
    return created;
  }

  @override
  Future<Bike> update(Bike bike) async {
    await _tick();
    final i = _store.bikes.indexWhere((b) => b.id == bike.id);
    if (i >= 0) _store.bikes[i] = bike;
    return bike;
  }

  @override
  Future<void> delete(String bikeId) async {
    await _tick();
    _store.bikes.removeWhere((b) => b.id == bikeId);
    _store.rides.removeWhere((r) => r.bikeId == bikeId);
    _store.records.removeWhere((r) => r.bikeId == bikeId);
  }

  @override
  Future<double> odometer(String bikeId) async {
    await _tick();
    return _store.odometerFor(bikeId);
  }

  Future<void> _tick() =>
      Future<void>.delayed(const Duration(milliseconds: 250));
}
