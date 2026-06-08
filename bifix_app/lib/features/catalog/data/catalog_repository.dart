import '../../../core/network/api_client.dart';
import '../domain/catalog.dart';

/// Read-only access to the brand / bike-model catalog. The bike form uses it to
/// let the user pick a model and autocomplete brand/model/year/battery.
abstract class CatalogRepository {
  Future<List<Brand>> brands();

  /// All bike models, each with its [Brand] embedded.
  Future<List<BikeModel>> models();
}

/// Talks to the real catalog endpoints. Not exercised while running on mock.
/// Endpoints (collections wrapped in `{data: [...]}`):
///   GET /brands · GET /bike-models
class HttpCatalogRepository implements CatalogRepository {
  HttpCatalogRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<Brand>> brands() async {
    final json = await _client.get('/brands');
    final list = (json['data'] as List?) ?? const [];
    return list
        .map((e) => Brand.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<List<BikeModel>> models() async {
    final json = await _client.get('/bike-models');
    final list = (json['data'] as List?) ?? const [];
    return list
        .map((e) => BikeModel.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}

/// In-memory catalog so the bike form's "search catalog" works standalone while
/// there is no backend. A small but realistic sample of popular e-bikes.
class MockCatalogRepository implements CatalogRepository {
  static const _specialized =
      Brand(id: '1', name: 'Specialized', slug: 'specialized', country: 'US');
  static const _trek = Brand(id: '2', name: 'Trek', slug: 'trek', country: 'US');
  static const _giant =
      Brand(id: '3', name: 'Giant', slug: 'giant', country: 'TW');
  static const _cannondale =
      Brand(id: '4', name: 'Cannondale', slug: 'cannondale', country: 'US');
  static const _radPower = Brand(
      id: '5', name: 'Rad Power Bikes', slug: 'rad-power-bikes', country: 'US');

  static const _li48 =
      BatteryType(id: '1', name: 'Li-ion 48V', slug: 'li-ion-48v');
  static const _li36 =
      BatteryType(id: '2', name: 'Li-ion 36V', slug: 'li-ion-36v');

  static const _brands = <Brand>[
    _specialized,
    _trek,
    _giant,
    _cannondale,
    _radPower,
  ];

  static const _models = <BikeModel>[
    BikeModel(
        id: '1',
        name: 'Turbo Vado 4.0',
        slug: 'turbo-vado-4-0',
        year: 2023,
        frameType: 'Urbana',
        motorBrand: 'Specialized 2.2',
        batteryWh: 710,
        rangeKm: 120,
        brand: _specialized,
        batteryType: _li48),
    BikeModel(
        id: '2',
        name: 'Turbo Levo Comp',
        slug: 'turbo-levo-comp',
        year: 2023,
        frameType: 'MTB',
        motorBrand: 'Specialized 2.2',
        batteryWh: 700,
        rangeKm: 90,
        brand: _specialized,
        batteryType: _li48),
    BikeModel(
        id: '3',
        name: 'Allant+ 7',
        slug: 'allant-plus-7',
        year: 2023,
        frameType: 'Urbana',
        motorBrand: 'Bosch Performance',
        batteryWh: 500,
        rangeKm: 100,
        brand: _trek,
        batteryType: _li36),
    BikeModel(
        id: '4',
        name: 'Powerfly 4',
        slug: 'powerfly-4',
        year: 2022,
        frameType: 'MTB',
        motorBrand: 'Bosch Performance',
        batteryWh: 500,
        rangeKm: 85,
        brand: _trek,
        batteryType: _li36),
    BikeModel(
        id: '5',
        name: 'Explore E+ 2',
        slug: 'explore-e-plus-2',
        year: 2023,
        frameType: 'Trekking',
        motorBrand: 'Giant SyncDrive',
        batteryWh: 625,
        rangeKm: 110,
        brand: _giant,
        batteryType: _li36),
    BikeModel(
        id: '6',
        name: 'Trance X E+ 3',
        slug: 'trance-x-e-plus-3',
        year: 2023,
        frameType: 'MTB',
        motorBrand: 'Giant SyncDrive',
        batteryWh: 625,
        rangeKm: 95,
        brand: _giant,
        batteryType: _li36),
    BikeModel(
        id: '7',
        name: 'Adventure Neo 3',
        slug: 'adventure-neo-3',
        year: 2022,
        frameType: 'Urbana',
        motorBrand: 'Bosch Active Line',
        batteryWh: 400,
        rangeKm: 80,
        brand: _cannondale,
        batteryType: _li36),
    BikeModel(
        id: '8',
        name: 'RadCity 5 Plus',
        slug: 'radcity-5-plus',
        year: 2023,
        frameType: 'Urbana',
        motorBrand: 'Geared Hub',
        batteryWh: 672,
        rangeKm: 80,
        brand: _radPower,
        batteryType: _li48),
  ];

  @override
  Future<List<Brand>> brands() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    return _brands;
  }

  @override
  Future<List<BikeModel>> models() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _models;
  }
}
