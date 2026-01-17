class SavedRoute {
  const SavedRoute({
    required this.id,
    required this.departureCity,
    required this.destinationCity,
    required this.departureCityName,
    required this.destinationCityName,
    this.type = 'CARGO',
  });

  final int id;
  final int departureCity;
  final int destinationCity;
  final String departureCityName;
  final String destinationCityName;

  final String type;

  bool get isCargo => type == 'CARGO';
  bool get isTransport => type == 'TRANSPORT';

  static const typeCargo = 'CARGO';
  static const typeTransport = 'TRANSPORT';

  factory SavedRoute.fromJson(Map<String, dynamic> json) {
    return SavedRoute(
      id: json['id'] as int,
      departureCity: json['departure_city'] as int,
      destinationCity: json['destination_city'] as int,
      departureCityName: json['departure_city_name'] as String,
      destinationCityName: json['destination_city_name'] as String,
      type: json['type'] as String? ?? typeCargo,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'departure_city': departureCity,
      'destination_city': destinationCity,
      'departure_city_name': departureCityName,
      'destination_city_name': destinationCityName,
      'type': type,
    };
  }
}
