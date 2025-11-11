class LocationModel {
  const LocationModel({
    required this.id,
    required this.cityName,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String cityName;
  final double? latitude;
  final double? longitude;

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id: json['id'] as int,
      cityName: json['city_name'] as String? ?? '',
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String && value.isNotEmpty) {
      return double.tryParse(value);
    }
    return null;
  }
}
