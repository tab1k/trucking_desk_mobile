import 'package:fura24.kz/features/client/domain/models/order_bid_info.dart';
import 'package:fura24.kz/features/locations/data/models/location_model.dart';

class OrderWaypointModel {
  const OrderWaypointModel({
    required this.id,
    required this.sequence,
    required this.location,
    this.addressDetail,
  });

  final int id;
  final int sequence;
  final LocationModel location;
  final String? addressDetail;

  factory OrderWaypointModel.fromJson(Map<String, dynamic> json) {
    return OrderWaypointModel(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse('${json['id']}') ?? 0,
      sequence: json['sequence'] is int
          ? json['sequence'] as int
          : int.tryParse('${json['sequence']}') ?? 0,
      location: LocationModel.fromJson(
        json['location'] as Map<String, dynamic>? ?? {},
      ),
      addressDetail: (json['address_detail'] as String?)?.trim(),
    );
  }
}

class OrderDetail {
  const OrderDetail({
    required this.id,
    required this.departurePoint,
    required this.destinationPoint,
    required this.cargoName,
    required this.vehicleType,
    required this.loadingType,
    required this.weightTons,
    required this.volumeCubicMeters,
    required this.lengthMeters,
    required this.widthMeters,
    required this.heightMeters,
    required this.description,
    required this.transportationDate,
    required this.transportationTermDays,
    required this.amount,
    required this.paymentType,
    required this.currency,
    required this.departureAddressDetail,
    required this.destinationAddressDetail,
    required this.showPhoneToDrivers,
    required this.status,
    required this.photoUrls,
    required this.waypoints,
    this.statusHistory = const [],
    this.bids = const [],
    this.lastLocation,
    this.currentDriverLocation,
    this.createdAt,
    this.acceptedAt,
    this.readyAt,
    this.pickupConfirmedAt,
    this.deliveryConfirmedAt,
    this.deliveredAt,
    this.pickupConfirmedByDriver = false,
    this.pickupConfirmedBySender = false,
    this.deliveryConfirmedByDriver = false,
    this.deliveryConfirmedBySender = false,
    this.isDriverSharingLocation = false,
    this.cancellationReason = '',
    this.driverId,
    this.senderId,
  });

  final String id;
  final String? senderId;
  final String? driverId;
  final String status;
  final LocationModel departurePoint;
  final LocationModel destinationPoint;
  final String cargoName;
  final String vehicleType;
  final String loadingType;
  final double weightTons;
  final double? volumeCubicMeters;
  final double? lengthMeters;
  final double? widthMeters;
  final double? heightMeters;
  final String? description;
  final DateTime? transportationDate;
  final int? transportationTermDays;
  final double amount;
  final String paymentType;
  final String currency;
  final String? departureAddressDetail;
  final String? destinationAddressDetail;
  final bool showPhoneToDrivers;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? readyAt;
  final DateTime? pickupConfirmedAt;
  final DateTime? deliveryConfirmedAt;
  final DateTime? deliveredAt;
  final bool pickupConfirmedByDriver;
  final bool pickupConfirmedBySender;
  final bool deliveryConfirmedByDriver;
  final bool deliveryConfirmedBySender;
  final bool isDriverSharingLocation;
  final String cancellationReason;
  final List<String> photoUrls;
  final List<OrderWaypointModel> waypoints;
  final List<OrderStatusHistoryEntry> statusHistory;
  final List<OrderBidInfo> bids;
  final OrderLocationPoint? lastLocation;
  final OrderLocationPoint? currentDriverLocation;

  bool get hasAssignedDriver => driverId != null && driverId!.isNotEmpty;

  String get driverName {
    if (driverId == null) return '';
    for (final bid in bids) {
      if (bid.driverId == driverId) {
        return bid.driverName;
      }
    }
    return '';
  }

  bool get isFinished => status == 'DELIVERED' || status == 'CANCELLED';

  factory OrderDetail.fromJson(Map<String, dynamic> json) {
    final departure = json['departure_point'] as Map<String, dynamic>? ?? {};
    final destination =
        json['destination_point'] as Map<String, dynamic>? ?? {};
    final waypoints =
        (json['waypoints'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(OrderWaypointModel.fromJson)
            .toList() ??
        const [];
    final history =
        (json['status_history'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(OrderStatusHistoryEntry.fromJson)
            .toList() ??
        const [];
    final bids =
        (json['bids'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(OrderBidInfo.fromJson)
            .toList() ??
        const [];
    final bidAmount = _bidAmountFromBids(bids);
    final photoUrls =
        (json['photos'] as List?)
            ?.whereType<String>()
            .where((url) => url.isNotEmpty)
            .toList() ??
        const [];
    final lastLocationMap = json['last_location'] as Map<String, dynamic>?;
    final currentDriverLocationMap =
        json['current_driver_location'] as Map<String, dynamic>?;

    return OrderDetail(
      id: (json['id'] ?? '').toString(),
      senderId: _idOrNull(json['sender']),
      driverId: _idOrNull(json['driver']),
      status: (json['status'] as String?) ?? 'PENDING',
      departurePoint: LocationModel.fromJson(departure),
      destinationPoint: LocationModel.fromJson(destination),
      cargoName: (json['cargo_name'] as String?) ?? '',
      vehicleType: (json['vehicle_type'] as String?) ?? 'ANY',
      loadingType: (json['loading_type'] as String?) ?? 'ANY',
      weightTons: _parseNum(json['weight']) ?? 0,
      volumeCubicMeters: _parseNum(json['volume_cubic_meters']),
      lengthMeters: _parseNum(json['length']),
      widthMeters: _parseNum(json['width']),
      heightMeters: _parseNum(json['height']),
      description: json['description'] as String?,
      transportationDate: _parseDate(json['transportation_date']),
      transportationTermDays: _parseInt(json['transportation_term_days']),
      amount: bidAmount ?? _parseNum(json['amount'] ?? json['total_cost']) ?? 0,
      paymentType: (json['payment_type'] as String?) ?? 'CASH',
      currency: (json['currency'] as String?) ?? 'KZT',
      departureAddressDetail: (json['departure_address_detail'] as String?)
          ?.trim(),
      destinationAddressDetail: (json['destination_address_detail'] as String?)
          ?.trim(),
      showPhoneToDrivers: json['show_phone_to_drivers'] as bool? ?? true,
      createdAt: _parseDate(json['created_at']),
      acceptedAt: _parseDate(json['accepted_at']),
      readyAt: _parseDate(json['ready_at']),
      pickupConfirmedAt: _parseDate(json['pickup_confirmed_at']),
      deliveryConfirmedAt: _parseDate(json['delivery_confirmed_at']),
      deliveredAt: _parseDate(json['delivered_at']),
      pickupConfirmedByDriver:
          json['pickup_confirmed_by_driver'] as bool? ?? false,
      pickupConfirmedBySender:
          json['pickup_confirmed_by_sender'] as bool? ?? false,
      deliveryConfirmedByDriver:
          json['delivery_confirmed_by_driver'] as bool? ?? false,
      deliveryConfirmedBySender:
          json['delivery_confirmed_by_sender'] as bool? ?? false,
      isDriverSharingLocation:
          json['is_driver_sharing_location'] as bool? ?? false,
      cancellationReason:
          (json['cancellation_reason'] as String?)?.trim() ?? '',
      photoUrls: photoUrls,
      waypoints: waypoints,
      statusHistory: history,
      bids: bids,
      lastLocation: lastLocationMap != null
          ? OrderLocationPoint.fromJson(lastLocationMap)
          : null,
      currentDriverLocation: currentDriverLocationMap != null
          ? OrderLocationPoint.fromJson(currentDriverLocationMap)
          : null,
    );
  }
}

double? _bidAmountFromBids(List<OrderBidInfo> bids) {
  if (bids.isEmpty) return null;
  const priority = <String>[
    'ACCEPTED',
    'WAITING_DRIVER_DECISION',
    'WAITING_DRIVER_CONFIRMATION',
  ];
  for (final status in priority) {
    for (final bid in bids) {
      if (bid.status == status && bid.amount != null) {
        return bid.amount;
      }
    }
  }
  // Fallback: first bid with amount
  for (final bid in bids) {
    if (bid.amount != null) return bid.amount;
  }
  return null;
}

class OrderStatusHistoryEntry {
  const OrderStatusHistoryEntry({
    required this.id,
    required this.status,
    required this.statusDisplay,
    required this.actorId,
    required this.actorName,
    required this.createdAt,
    required this.comment,
  });

  final String id;
  final String status;
  final String statusDisplay;
  final String? actorId;
  final String actorName;
  final String comment;
  final DateTime? createdAt;

  factory OrderStatusHistoryEntry.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryEntry(
      id: (json['id'] ?? '').toString(),
      status: (json['status'] as String?) ?? '',
      statusDisplay: (json['status_display'] as String?) ?? '',
      actorId: _idOrNull(json['actor']),
      actorName: (json['actor_name'] as String?)?.trim() ?? '',
      comment: (json['comment'] as String?)?.trim() ?? '',
      createdAt: _parseDate(json['created_at']),
    );
  }
}

class OrderLocationPoint {
  const OrderLocationPoint({
    required this.latitude,
    required this.longitude,
    required this.reportedAt,
    required this.note,
  });

  final double latitude;
  final double longitude;
  final DateTime? reportedAt;
  final String note;

  factory OrderLocationPoint.fromJson(Map<String, dynamic> json) {
    return OrderLocationPoint(
      latitude: (_parseNum(json['latitude']) ?? 0).toDouble(),
      longitude: (_parseNum(json['longitude']) ?? 0).toDouble(),
      reportedAt: _parseDate(json['reported_at']),
      note: (json['note'] as String?)?.trim() ?? '',
    );
  }
}

String? _idOrNull(dynamic value) {
  if (value == null) return null;
  final stringValue = value.toString();
  return stringValue.isEmpty ? null : stringValue;
}

double? _parseNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String && value.isNotEmpty) {
    return double.tryParse(value);
  }
  return null;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is String && value.isNotEmpty) {
    return int.tryParse(value);
  }
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }
  return null;
}
