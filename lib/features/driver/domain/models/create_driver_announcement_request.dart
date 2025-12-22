import 'package:fura24.kz/features/client/domain/models/create_order_request.dart';

class CreateDriverAnnouncementRequest {
  const CreateDriverAnnouncementRequest({
    required this.departurePointId,
    required this.destinationPointId,
    required this.vehicleType,
    required this.loadingType,
    required this.weight,
    this.volume,
    this.comment = '',
    this.isActive = true,
    this.waypoints = const [],
  });

  final int departurePointId;
  final int destinationPointId;
  final String vehicleType;
  final String loadingType;
  final double weight;
  final double? volume;
  final String comment;
  final bool isActive;
  final List<OrderWaypointRequest> waypoints;

  Map<String, dynamic> toJson() {
    final hasWaypoints = waypoints.length > 2;
    final payload = <String, dynamic>{
      'vehicle_type': vehicleType,
      'loading_type': loadingType,
      'weight': weight,
      'comment': comment.trim(),
      'is_active': isActive,
    };

    if (hasWaypoints) {
      final first = waypoints.first;
      final last = waypoints.last;
      payload['departure_point_id'] = first.locationId;
      payload['destination_point_id'] = last.locationId;
      payload['waypoints_input'] = waypoints
          .asMap()
          .entries
          .map(
            (entry) => {
              'location': entry.value.locationId,
              'sequence': entry.value.sequence ?? (entry.key + 1),
            },
          )
          .toList();
    } else {
      payload['departure_point_id'] = departurePointId;
      payload['destination_point_id'] = destinationPointId;
    }

    if (volume != null) {
      payload['volume_cubic_meters'] = volume;
    }
    return payload;
  }
}
