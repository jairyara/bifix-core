/// Reference catalog served by the backend: brands, bike models and battery
/// types used to identify a bike precisely. Read-only on the client.
///
/// NOTE: `fromJson` mirrors the Laravel API resources (snake_case), which is
/// the agreed project-wide convention — every model serializes in snake_case
/// to match the backend. These mappings are exercised only against the real
/// API (the catalog HTTP repo).
library;

class Brand {
  const Brand({
    required this.id,
    required this.name,
    required this.slug,
    this.country,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String slug;
  final String? country;
  final String? logoUrl;

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        country: json['country'] as String?,
        logoUrl: json['logo_url'] as String?,
      );
}

class BatteryType {
  const BatteryType({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;

  factory BatteryType.fromJson(Map<String, dynamic> json) => BatteryType(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        description: json['description'] as String?,
      );
}

class BikeModel {
  const BikeModel({
    required this.id,
    required this.name,
    required this.slug,
    this.year,
    this.frameType,
    this.motorBrand,
    this.batteryWh,
    this.rangeKm,
    this.brand,
    this.batteryType,
  });

  final String id;
  final String name;
  final String slug;
  final int? year;
  final String? frameType;
  final String? motorBrand;
  final int? batteryWh;
  final int? rangeKm;
  final Brand? brand;
  final BatteryType? batteryType;

  /// e.g. "Specialized Turbo Vado 4.0".
  String get fullName =>
      [brand?.name, name].whereType<String>().join(' ').trim();

  /// Lowercased haystack for the picker's search box.
  String get searchKey =>
      [brand?.name, name, year?.toString(), motorBrand].whereType<String>().join(' ').toLowerCase();

  factory BikeModel.fromJson(Map<String, dynamic> json) => BikeModel(
        id: json['id'].toString(),
        name: json['name'] as String? ?? '',
        slug: json['slug'] as String? ?? '',
        year: (json['year'] as num?)?.toInt(),
        frameType: json['frame_type'] as String?,
        motorBrand: json['motor_brand'] as String?,
        batteryWh: (json['battery_wh'] as num?)?.toInt(),
        rangeKm: (json['range_km'] as num?)?.toInt(),
        brand: json['brand'] is Map<String, dynamic>
            ? Brand.fromJson(json['brand'] as Map<String, dynamic>)
            : null,
        batteryType: json['battery_type'] is Map<String, dynamic>
            ? BatteryType.fromJson(json['battery_type'] as Map<String, dynamic>)
            : null,
      );
}
