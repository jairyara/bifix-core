import '../../../core/mock/mock_store.dart';
import '../../../core/network/api_client.dart';
import '../domain/maintenance.dart';

abstract class MaintenanceRepository {
  /// Catalog of maintenance tasks with their recommended intervals.
  Future<List<MaintenanceTask>> tasks();

  Future<List<MaintenanceRecord>> recordsByBike(String bikeId);

  Future<MaintenanceRecord> addRecord(MaintenanceRecord record);

  Future<void> deleteRecord(String recordId);
}

class HttpMaintenanceRepository implements MaintenanceRepository {
  HttpMaintenanceRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<MaintenanceTask>> tasks() async {
    final json = await _client.get('/maintenance/tasks');
    final data = (json['data'] as List?) ?? const [];
    return data
        .map((e) => MaintenanceTask.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<List<MaintenanceRecord>> recordsByBike(String bikeId) async {
    final json = await _client.get('/bikes/$bikeId/maintenance');
    final data = (json['data'] as List?) ?? const [];
    return data
        .map((e) => MaintenanceRecord.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<MaintenanceRecord> addRecord(MaintenanceRecord record) async {
    final json = await _client.post('/bikes/${record.bikeId}/maintenance',
        body: record.toJson());
    return MaintenanceRecord.fromJson(json);
  }

  @override
  Future<void> deleteRecord(String recordId) =>
      _client.delete('/maintenance/$recordId');
}

class MockMaintenanceRepository implements MaintenanceRepository {
  final MockStore _store = MockStore.instance;

  @override
  Future<List<MaintenanceTask>> tasks() async {
    await _tick();
    return List.of(_store.tasks);
  }

  @override
  Future<List<MaintenanceRecord>> recordsByBike(String bikeId) async {
    await _tick();
    final list = _store.records.where((r) => r.bikeId == bikeId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<MaintenanceRecord> addRecord(MaintenanceRecord record) async {
    await _tick();
    final created = record.id.isEmpty
        ? MaintenanceRecord(
            id: _store.nextId('rec'),
            bikeId: record.bikeId,
            taskId: record.taskId,
            date: record.date,
            odometerKm: record.odometerKm,
            notes: record.notes,
            costCents: record.costCents,
          )
        : record;
    _store.records.add(created);
    return created;
  }

  @override
  Future<void> deleteRecord(String recordId) async {
    await _tick();
    _store.records.removeWhere((r) => r.id == recordId);
  }

  Future<void> _tick() =>
      Future<void>.delayed(const Duration(milliseconds: 250));
}
