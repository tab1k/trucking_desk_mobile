import 'package:fura24.kz/features/locations/data/models/location_model.dart';

class DriverAnnouncementWaypoint {
  const DriverAnnouncementWaypoint({
    required this.id,
    required this.sequence,
    required this.location,
  });

  final String id;
  final int sequence;
  final LocationModel location;

  factory DriverAnnouncementWaypoint.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>? ?? {};
    return DriverAnnouncementWaypoint(
      id: (json['id'] ?? '').toString(),
      sequence: json['sequence'] is int
          ? json['sequence'] as int
          : int.tryParse('${json['sequence']}') ?? 0,
      location: LocationModel.fromJson(loc),
    );
  }
}

class DriverAnnouncement {
  const DriverAnnouncement({
    required this.id,
    required this.driverId,
    required this.driverFullName,
    required this.departurePoint,
    required this.destinationPoint,
    required this.waypoints,
    required this.vehicleType,
    required this.vehicleTypeDisplay,
    required this.loadingType,
    required this.loadingTypeDisplay,
    required this.weight,
    required this.volume,
    required this.comment,
    required this.isActive,
    required this.createdAt,
    required this.driverRating,
    required this.driverPhoneNumber,
    required this.isFavorite,
  });

  final String id;
  final int driverId;
  final String driverFullName;
  final LocationModel departurePoint;
  final LocationModel destinationPoint;
  final List<DriverAnnouncementWaypoint> waypoints;
  final String vehicleType;
  final String vehicleTypeDisplay;
  final String loadingType;
  final String loadingTypeDisplay;
  final double weight;
  final double? volume;
  final String comment;
  final bool isActive;
  final DateTime createdAt;
  final double driverRating;
  final String driverPhoneNumber;
  final bool isFavorite;

  factory DriverAnnouncement.fromJson(Map<String, dynamic> json) {
    final departure = json['departure_point'] as Map<String, dynamic>? ?? {};
    final destination =
        json['destination_point'] as Map<String, dynamic>? ?? {};
    final waypointMaps =
        (json['waypoints'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const [];
    final waypointModels =
        waypointMaps.map(DriverAnnouncementWaypoint.fromJson).toList();

    return DriverAnnouncement(
      id: (json['id'] ?? '').toString(),
      driverId: json['driver'] as int? ?? 0,
      driverFullName: (json['driver_full_name'] as String?)?.trim() ?? '',
      departurePoint: waypointModels.isNotEmpty
          ? waypointModels.first.location
          : LocationModel.fromJson(departure),
      destinationPoint: waypointModels.isNotEmpty
          ? waypointModels.last.location
          : LocationModel.fromJson(destination),
      waypoints: waypointModels,
      vehicleType: (json['vehicle_type'] as String?) ?? 'ANY',
      vehicleTypeDisplay:
          (json['vehicle_type_display'] as String?) ?? 'Любой транспорт',
      loadingType: (json['loading_type'] as String?) ?? 'ANY',
      loadingTypeDisplay:
          (json['loading_type_display'] as String?) ?? 'Любая погрузка',
      weight: _parseDouble(json['weight']) ?? 0,
      volume: _parseDouble(json['volume_cubic_meters']),
      comment: (json['comment'] as String?) ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: _parseDate(json['created_at']) ?? DateTime.now(),
      driverRating: _parseDriverRating(json['driver_rating']),
      driverPhoneNumber: (json['driver_phone_number'] as String?)?.trim() ?? '',
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  String routeLabel() {
    if (waypoints.length > 2) {
      final first = waypoints.first.location.cityName;
      final last = waypoints.last.location.cityName;
      return '$first → … → $last';
    }
    return '${departurePoint.cityName} → ${destinationPoint.cityName}';
  }

  static double _parseDriverRating(dynamic value) {
    final parsed = _parseDouble(value) ?? 1;
    if (parsed < 1) return 1;
    if (parsed > 5) return 5;
    return parsed;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String && value.isNotEmpty) {
      return double.tryParse(value);
    }
    return null;
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
