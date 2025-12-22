import 'package:fura24.kz/features/client/domain/models/order_summary.dart';

class DriverCargoFilters {
  const DriverCargoFilters({
    this.departureCity = '',
    this.destinationCity = '',
    this.vehicleType = '',
    this.minAmount,
    this.maxAmount,
    this.onlyWithCall = false,
    this.departurePointId,
    this.destinationPointId,
    this.transportationDate,
  });

  final String departureCity;
  final String destinationCity;
  final String vehicleType;
  final double? minAmount;
  final double? maxAmount;
  final bool onlyWithCall;
  final int? departurePointId;
  final int? destinationPointId;
  final DateTime? transportationDate;

  bool get isEmpty =>
      departurePointId == null &&
      destinationPointId == null &&
      vehicleType.isEmpty &&
      minAmount == null &&
      maxAmount == null &&
      !onlyWithCall &&
      transportationDate == null;

  DriverCargoFilters copyWith({
    String? departureCity,
    String? destinationCity,
    String? vehicleType,
    double? minAmount,
    double? maxAmount,
    bool? onlyWithCall,
    int? departurePointId,
    int? destinationPointId,
    DateTime? transportationDate,
  }) {
    return DriverCargoFilters(
      departureCity: departureCity ?? this.departureCity,
      destinationCity: destinationCity ?? this.destinationCity,
      vehicleType: vehicleType ?? this.vehicleType,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      onlyWithCall: onlyWithCall ?? this.onlyWithCall,
      departurePointId: departurePointId ?? this.departurePointId,
      destinationPointId: destinationPointId ?? this.destinationPointId,
      transportationDate: transportationDate ?? this.transportationDate,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};
    if (departurePointId != null) {
      params['departure_point'] = departurePointId;
    }
    if (destinationPointId != null) {
      params['destination_point'] = destinationPointId;
    }
    if (vehicleType.isNotEmpty) {
      params['vehicle_type'] = vehicleType;
    }
    if (minAmount != null) {
      params['min_amount'] = minAmount;
    }
    if (maxAmount != null) {
      params['max_amount'] = maxAmount;
    }
    if (transportationDate != null) {
      final date = transportationDate!;
      params['transportation_date'] =
          '${date.year.toString().padLeft(4, '0')}-'
          '${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}';
    }
    return params;
  }

  bool matches(OrderSummary order) {
    if (onlyWithCall && !order.canDriverCall) {
      return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DriverCargoFilters &&
        other.departureCity == departureCity &&
        other.destinationCity == destinationCity &&
        other.vehicleType == vehicleType &&
        other.minAmount == minAmount &&
        other.maxAmount == maxAmount &&
        other.onlyWithCall == onlyWithCall &&
        other.departurePointId == departurePointId &&
        other.destinationPointId == destinationPointId &&
        other.transportationDate == transportationDate;
  }

  @override
  int get hashCode => Object.hash(
    departureCity,
    destinationCity,
    vehicleType,
    minAmount,
    maxAmount,
    onlyWithCall,
    departurePointId,
    destinationPointId,
    transportationDate,
  );
}
