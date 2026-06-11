/// An electric bicycle owned by the user. The maintenance engine works against
/// the bike's accumulated distance ([totalDistanceKm]).
class Bike {
  const Bike({
    required this.id,
    required this.name,
    this.brand,
    this.model,
    this.year,
    this.batteryWh,
    this.baselineKm = 0,
    this.purchaseDate,
  });

  final String id;
  final String name;
  final String? brand;
  final String? model;
  final int? year;

  /// Battery capacity in watt-hours (helps future range estimates).
  final int? batteryWh;

  /// Odometer reading already on the bike when it was added to the app.
  /// Total distance = [baselineKm] + sum of logged rides (computed elsewhere).
  final double baselineKm;

  final DateTime? purchaseDate;

  String get displayModel => [brand, model].whereType<String>().join(' ').trim();

  factory Bike.fromJson(Map<String, dynamic> json) {
    return Bike(
      id: json['id'].toString(),
      name: json['name'] as String? ?? 'Mi bici',
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      year: (json['year'] as num?)?.toInt(),
      batteryWh: (json['battery_wh'] as num?)?.toInt(),
      baselineKm: (json['baseline_km'] as num?)?.toDouble() ?? 0,
      purchaseDate: json['purchase_date'] != null
          ? DateTime.tryParse(json['purchase_date'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (brand != null) 'brand': brand,
        if (model != null) 'model': model,
        if (year != null) 'year': year,
        if (batteryWh != null) 'battery_wh': batteryWh,
        'baseline_km': baselineKm,
        if (purchaseDate != null)
          'purchase_date': purchaseDate!.toIso8601String(),
      };

  Bike copyWith({
    String? name,
    String? brand,
    String? model,
    int? year,
    int? batteryWh,
    double? baselineKm,
    DateTime? purchaseDate,
  }) {
    return Bike(
      id: id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      batteryWh: batteryWh ?? this.batteryWh,
      baselineKm: baselineKm ?? this.baselineKm,
      purchaseDate: purchaseDate ?? this.purchaseDate,
    );
  }
}
