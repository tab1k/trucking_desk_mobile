import 'package:easy_localization/easy_localization.dart';
import 'package:fura24.kz/features/client/domain/models/order_detail.dart';
import 'package:fura24.kz/features/locations/data/models/location_model.dart';

enum CargoStatus { pending, inTransit, completed, cancelled }

class OrderSummary {
  final String id;
  final String cargoName;
  final String routeLabel;
  final String weightLabel;
  final String volumeLabel;
  final String priceLabel;
  final String dateLabel;
  final CargoStatus status;
  final String rawStatus;
  final String description;
  final String vehicleTypeLabel;
  final String loadingTypeLabel;
  final String paymentTypeLabel;
  final String vehicleType;
  final String loadingType;
  final String paymentType;
  final String departureCity;
  final String destinationCity;
  final bool isFavoriteForDriver;
  final double? amountValue;
  final String currencyCode;
  final bool showPhoneToDrivers;
  final String senderPhoneNumber;
  final String? senderId;
  final String? driverId;
  final bool canDriverCall;
  final bool isDriverSharingLocation;
  final int bidsCount;
  final bool hasNewBids;
  final List<String> bidDriverPreviewIds;
  final bool hasResponded;
  final List<String> photoUrls;
  final String senderName;
  final String? senderAvatarUrl;
  final DateTime? transportationDate;
  final DateTime? createdAt;
  final double? departureLatitude;
  final double? departureLongitude;
  final double? destinationLatitude;
  final double? destinationLongitude;
  final double? distanceKm;
  final OrderSummaryLocation? lastLocation;
  final OrderSummaryLocation? currentDriverLocation;
  final List<OrderWaypointSummary> waypoints;

  const OrderSummary({
    required this.id,
    required this.cargoName,
    required this.routeLabel,
    required this.weightLabel,
    required this.volumeLabel,
    required this.priceLabel,
    required this.dateLabel,
    required this.status,
    required this.description,
    required this.vehicleTypeLabel,
    required this.loadingTypeLabel,
    required this.paymentTypeLabel,
    this.vehicleType = 'ANY',
    this.loadingType = 'ANY',
    this.paymentType = 'CASH',
    required this.departureCity,
    required this.destinationCity,
    required this.isFavoriteForDriver,
    this.amountValue,
    this.currencyCode = '',
    this.showPhoneToDrivers = true,
    this.senderPhoneNumber = '',
    this.senderId,
    this.driverId,
    this.canDriverCall = false,
    this.isDriverSharingLocation = false,
    this.bidsCount = 0,
    this.hasNewBids = false,
    this.bidDriverPreviewIds = const [],
    this.hasResponded = false,
    this.photoUrls = const [],
    this.senderName = 'Имя не указано',
    this.transportationDate,
    this.createdAt,
    this.rawStatus = '',
    this.departureLatitude,
    this.departureLongitude,
    this.destinationLatitude,
    this.destinationLongitude,
    this.distanceKm,
    this.lastLocation,
    this.currentDriverLocation,
    this.waypoints = const [],
    this.senderAvatarUrl,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> json) {
    final waypointMaps =
        (json['waypoints'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        const [];
    final waypointModels = waypointMaps
        .map(OrderWaypointSummary.fromJson)
        .toList();

    final departure = waypointModels.isNotEmpty
        ? waypointModels.first.location
        : json['departure_point'] as Map<String, dynamic>?;
    final destination = waypointModels.isNotEmpty
        ? waypointModels.last.location
        : json['destination_point'] as Map<String, dynamic>?;
    final departureLat = _parseNum(departure?['latitude'])?.toDouble();
    final departureLng = _parseNum(departure?['longitude'])?.toDouble();
    final destinationLat = _parseNum(destination?['latitude'])?.toDouble();
    final destinationLng = _parseNum(destination?['longitude'])?.toDouble();

    final weightValue = _parseNum(json['weight']);
    final volumeValue = _parseNum(json['volume_cubic_meters']);
    final amountRaw = _parseNum(json['amount'] ?? json['total_cost']);
    final currency = (json['currency'] as String?)?.toUpperCase();
    final transportDateString = json['transportation_date'] as String?;
    final createdAtString = json['created_at'] as String?;
    final dateString = transportDateString ?? createdAtString;
    final rawCargoName = (json['cargo_name'] as String?)?.trim();
    final displayCargoName = rawCargoName != null && rawCargoName.isNotEmpty
        ? rawCargoName
        : 'Без названия';
    final description = (json['description'] as String?)?.trim() ?? '';
    final vehicleType = (json['vehicle_type'] as String?) ?? 'ANY';
    final vehicleTypeLabel = _labelOrDash(
      json['vehicle_type_display'] as String?,
    );
    final loadingType = (json['loading_type'] as String?) ?? 'ANY';
    final loadingTypeLabel = _labelOrDash(
      json['loading_type_display'] as String?,
    );
    final paymentType = (json['payment_type'] as String?) ?? 'CASH';
    final paymentTypeLabel = _labelOrDash(
      json['payment_type_display'] as String?,
    );
    final departureCity = _cityName(departure);
    final destinationCity = _cityName(destination);
    final isFavoriteForDriver =
        json['is_favorite_for_driver'] as bool? ?? false;
    final showPhoneToDrivers = json['show_phone_to_drivers'] as bool? ?? true;
    final senderPhoneNumber =
        (json['sender_phone_number'] as String?)?.trim() ?? '';
    final senderId = _idOrNull(json['sender']);
    final driverId = _idOrNull(json['driver']);
    final canDriverCall = showPhoneToDrivers && senderPhoneNumber.isNotEmpty;
    final bidsRaw = json['bids'];
    var bidsCount = 0;
    var hasNewBids = false;
    final previewIds = <String>[];
    final bidAmount = _bidAmountFromSummary(bidsRaw);
    if (bidsRaw is List) {
      bidsCount = bidsRaw.length;
      for (final item in bidsRaw.whereType<Map<String, dynamic>>()) {
        final status = (item['status'] as String?) ?? '';
        if (!hasNewBids && (status.isEmpty || status == 'PENDING')) {
          hasNewBids = true;
        }
        if (previewIds.length < 5) {
          final driverName =
              (item['driver_full_name'] as String?)?.trim() ??
              (item['driver_phone_number'] as String?)?.trim() ??
              (item['driver']?.toString()) ??
              'Водитель';
          previewIds.add(driverName);
        }
      }
    }
    final hasResponded = bidsCount > 0;
    final senderName = (json['sender_name'] as String?)?.trim();
    final photoUrls =
        (json['photos'] as List?)
            ?.whereType<String>()
            .where((url) => url.isNotEmpty)
            .toList() ??
        const [];
    final senderAvatarUrl = json['sender_avatar'] as String?;
    final lastLocationMap = json['last_location'] as Map<String, dynamic>?;
    final currentDriverLocationMap =
        json['current_driver_location'] as Map<String, dynamic>?;
    final lastLocation = lastLocationMap != null
        ? OrderSummaryLocation.fromJson(lastLocationMap)
        : null;
    final currentDriverLocation = currentDriverLocationMap != null
        ? OrderSummaryLocation.fromJson(currentDriverLocationMap)
        : null;
    final resolvedAmount = bidAmount ?? amountRaw;

    return OrderSummary(
      id: (json['id'] ?? '').toString(),
      cargoName: displayCargoName,
      routeLabel: _buildRoute(waypointModels, departure, destination),
      weightLabel: _formatWeight(weightValue),
      volumeLabel: _formatVolume(volumeValue),
      priceLabel: _formatCurrency(resolvedAmount, currency),
      dateLabel: _formatDate(dateString),
      status: _mapStatus((json['status'] as String?) ?? ''),
      description: description,
      vehicleTypeLabel: vehicleTypeLabel,
      loadingTypeLabel: loadingTypeLabel,
      paymentTypeLabel: paymentTypeLabel,
      vehicleType: vehicleType,
      loadingType: loadingType,
      paymentType: paymentType,
      departureCity: departureCity,
      destinationCity: destinationCity,
      isFavoriteForDriver: isFavoriteForDriver,
      amountValue: resolvedAmount?.toDouble(),
      currencyCode: currency ?? '',
      showPhoneToDrivers: showPhoneToDrivers,
      senderPhoneNumber: senderPhoneNumber,
      senderId: senderId,
      driverId: driverId,
      canDriverCall: canDriverCall,
      isDriverSharingLocation:
          json['is_driver_sharing_location'] as bool? ?? false,
      bidsCount: bidsCount,
      hasNewBids: hasNewBids,
      bidDriverPreviewIds: previewIds,
      hasResponded: hasResponded,
      photoUrls: photoUrls,
      senderName: senderName == null || senderName.isEmpty
          ? 'Имя не указано'
          : senderName,
      senderAvatarUrl: senderAvatarUrl,
      transportationDate: _parseDate(transportDateString),
      createdAt: _parseDate(createdAtString),
      rawStatus: (json['status'] as String?) ?? '',
      departureLatitude: departureLat,
      departureLongitude: departureLng,
      destinationLatitude: destinationLat,
      destinationLongitude: destinationLng,
      distanceKm: _parseNum(json['distance_km'])?.toDouble(),
      lastLocation: lastLocation,
      currentDriverLocation: currentDriverLocation,
      waypoints: waypointModels,
    );
  }

  factory OrderSummary.fromDetail(OrderDetail detail) {
    return OrderSummary(
      id: detail.id,
      cargoName: detail.cargoName,
      routeLabel: _buildRouteFromModels(
        detail.waypoints,
        detail.departurePoint,
        detail.destinationPoint,
      ),
      weightLabel: _formatWeight(detail.weightTons),
      volumeLabel: _formatVolume(detail.volumeCubicMeters),
      priceLabel: _formatCurrency(detail.amount, detail.currency),
      dateLabel: _formatDate(detail.transportationDate?.toIso8601String()),
      status: _mapStatus(detail.status),
      description: detail.description ?? '',
      vehicleTypeLabel: tr('cargo_types.vehicle.${detail.vehicleType}'),
      loadingTypeLabel: tr('cargo_types.loading.${detail.loadingType}'),
      paymentTypeLabel: tr('cargo_types.payment.${detail.paymentType}'),
      vehicleType: detail.vehicleType,
      loadingType: detail.loadingType,
      paymentType: detail.paymentType,
      departureCity: detail.departurePoint.cityName ?? '',
      destinationCity: detail.destinationPoint.cityName ?? '',
      isFavoriteForDriver: false,
      amountValue: detail.amount,
      currencyCode: detail.currency,
      showPhoneToDrivers: detail.showPhoneToDrivers,
      senderPhoneNumber: '',
      senderId: detail.senderId,
      driverId: detail.driverId,
      canDriverCall: false,
      isDriverSharingLocation: detail.isDriverSharingLocation,
      bidsCount: detail.bids.length,
      hasNewBids: false,
      bidDriverPreviewIds: [],
      hasResponded: detail.bids.any((b) => b.driverId == detail.driverId),
      photoUrls: detail.photoUrls,
      senderName: '', // Sender name might be missing in detail
      transportationDate: detail.transportationDate,
      createdAt: detail.createdAt,
      rawStatus: detail.status,
      departureLatitude: detail.departurePoint.latitude,
      departureLongitude: detail.departurePoint.longitude,
      destinationLatitude: detail.destinationPoint.latitude,
      destinationLongitude: detail.destinationPoint.longitude,
      lastLocation: detail.lastLocation != null
          ? OrderSummaryLocation(
              latitude: detail.lastLocation!.latitude,
              longitude: detail.lastLocation!.longitude,
              note: detail.lastLocation!.note,
              reportedAt: detail.lastLocation!.reportedAt,
            )
          : null,
      currentDriverLocation: detail.currentDriverLocation != null
          ? OrderSummaryLocation(
              latitude: detail.currentDriverLocation!.latitude,
              longitude: detail.currentDriverLocation!.longitude,
              note: detail.currentDriverLocation!.note,
              reportedAt: detail.currentDriverLocation!.reportedAt,
            )
          : null,
      waypoints: detail.waypoints
          .map(
            (w) => OrderWaypointSummary(
              id: w.id.toString(),
              sequence: w.sequence,
              location: {
                'city_name': w.location.cityName,
                'latitude': w.location.latitude,
                'longitude': w.location.longitude,
              },
              addressDetail: w.addressDetail,
            ),
          )
          .toList(),
      senderAvatarUrl: null,
    );
  }
}

class OrderSummaryLocation {
  const OrderSummaryLocation({
    required this.latitude,
    required this.longitude,
    required this.note,
    this.reportedAt,
  });

  final double latitude;
  final double longitude;
  final String note;
  final DateTime? reportedAt;

  factory OrderSummaryLocation.fromJson(Map<String, dynamic> json) {
    return OrderSummaryLocation(
      latitude: (_parseNum(json['latitude']) ?? 0).toDouble(),
      longitude: (_parseNum(json['longitude']) ?? 0).toDouble(),
      note: (json['note'] as String?)?.trim() ?? '',
      reportedAt: _parseDate(json['reported_at']),
    );
  }
}

class OrderWaypointSummary {
  final String id;
  final int sequence;
  final Map<String, dynamic> location;
  final String? addressDetail;

  OrderWaypointSummary({
    required this.id,
    required this.sequence,
    required this.location,
    this.addressDetail,
  });

  factory OrderWaypointSummary.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] as Map<String, dynamic>? ?? {};
    return OrderWaypointSummary(
      id: (json['id'] ?? '').toString(),
      sequence: _parseInt(json['sequence']) ?? 0,
      location: loc,
      addressDetail: (json['address_detail'] as String?)?.trim(),
    );
  }
}

CargoStatus _mapStatus(String status) {
  switch (status) {
    case 'IN_PROGRESS':
    case 'ACCEPTED':
    case 'READY_FOR_PICKUP':
    case 'WAITING_DRIVER_CONFIRMATION':
    case 'WAITING_PICKUP_CONFIRMATION':
    case 'WAITING_DELIVERY_CONFIRMATION':
      return CargoStatus.inTransit;
    case 'DELIVERED':
      return CargoStatus.completed;
    case 'CANCELLED':
      return CargoStatus.cancelled;
    default:
      return CargoStatus.pending;
  }
}

String _buildRoute(
  List<OrderWaypointSummary> waypoints,
  Map<String, dynamic>? departure,
  Map<String, dynamic>? destination,
) {
  const emptyLabel = 'Не указано';
  if (waypoints.isNotEmpty) {
    final cities = waypoints
        .map((w) => _cityName(w.location, fallback: ''))
        .where((c) => c.isNotEmpty)
        .toList();
    if (cities.length >= 2) {
      if (cities.length > 2) {
        return '${cities.first} → … → ${cities.last}';
      }
      return cities.join(' → ');
    }
  }
  final from = _cityName(departure, fallback: emptyLabel);
  final to = _cityName(destination, fallback: emptyLabel);
  return '$from → $to';
}

String _buildRouteFromModels(
  List<OrderWaypointModel> waypoints,
  LocationModel departure,
  LocationModel destination,
) {
  if (waypoints.isNotEmpty) {
    final cities = waypoints
        .map((w) => w.location.cityName)
        .where((c) => c.isNotEmpty)
        .toList();
    if (cities.length >= 2) {
      if (cities.length > 2) {
        return '${cities.first} → … → ${cities.last}';
      }
      return cities.join(' → ');
    }
  }
  return '${departure.cityName} → ${destination.cityName}';
}

String _cityName(
  Map<String, dynamic>? point, {
  String fallback = 'Не указано',
}) {
  return (point?['city_name'] as String?) ?? fallback;
}

num? _parseNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

int? _parseInt(dynamic value) {
  final numValue = _parseNum(value);
  return numValue?.toInt();
}

double? _bidAmountFromSummary(dynamic bidsRaw) {
  if (bidsRaw is! List) return null;
  const priority = <String>[
    'ACCEPTED',
    'WAITING_DRIVER_DECISION',
    'WAITING_DRIVER_CONFIRMATION',
  ];
  for (final status in priority) {
    for (final item in bidsRaw.whereType<Map<String, dynamic>>()) {
      if (item['status'] == status) {
        final amount = _parseNum(item['amount']);
        if (amount != null) return amount.toDouble();
      }
    }
  }
  for (final item in bidsRaw.whereType<Map<String, dynamic>>()) {
    final amount = _parseNum(item['amount']);
    if (amount != null) return amount.toDouble();
  }
  return null;
}

String _formatWeight(num? weight) {
  if (weight == null) return '—';
  return '${_formatNumber(weight)} т';
}

String _formatVolume(num? volume) {
  if (volume == null) return '—';
  return '${_formatNumber(volume)} м³';
}

String _formatCurrency(num? amount, String? currencyCode) {
  if (amount == null) return '—';
  final symbol = _currencySymbols[currencyCode] ?? currencyCode ?? '';
  return '$symbol${_formatNumber(amount)}';
}

DateTime? _parseDate(String? value) {
  if (value == null || value.isEmpty) return null;
  try {
    return DateTime.parse(value);
  } catch (_) {
    return null;
  }
}

const _currencySymbols = {
  'KZT': '₸',
  'RUB': '₽',
  'USD': r'$',
  'EUR': '€',
  'CNY': '¥',
  'KGS': 'сом ',
};

String _formatNumber(num value) {
  final normalized = value.toDouble();
  final decimalPlaces = normalized % 1 == 0 ? 0 : 2;
  var formatted = normalized.toStringAsFixed(decimalPlaces);
  if (decimalPlaces > 0) {
    formatted = formatted.replaceFirst(RegExp(r'0+$'), '');
    formatted = formatted.replaceFirst(RegExp(r'\.$'), '');
  }
  return formatted;
}

String _formatDate(String? raw) {
  if (raw == null || raw.isEmpty) return '—';
  try {
    final parsed = DateTime.parse(raw);
    const months = [
      '',
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    final month = months[parsed.month];
    return '${parsed.day} $month';
  } catch (_) {
    return raw;
  }
}

String _labelOrDash(String? value) {
  if (value == null || value.trim().isEmpty) return '—';
  return value.trim();
}

String? _idOrNull(dynamic value) {
  if (value == null) return null;
  final stringValue = value.toString();
  return stringValue.isEmpty ? null : stringValue;
}
