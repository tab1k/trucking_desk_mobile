class DriverAnnouncementFilters {
  const DriverAnnouncementFilters({
    this.departureCity = '',
    this.destinationCity = '',
    this.vehicleType = '',
    this.loadingType = '',
    this.weightFrom,
    this.weightTo,
    this.volumeFrom,
    this.volumeTo,
    this.createdDate,
  });

  final String departureCity;
  final String destinationCity;
  final String vehicleType;
  final String loadingType;
  final double? weightFrom;
  final double? weightTo;
  final double? volumeFrom;
  final double? volumeTo;
  final DateTime? createdDate;

  DriverAnnouncementFilters copyWith({
    String? departureCity,
    String? destinationCity,
    String? vehicleType,
    String? loadingType,
    double? weightFrom,
    double? weightTo,
    double? volumeFrom,
    double? volumeTo,
    DateTime? createdDate,
  }) {
    return DriverAnnouncementFilters(
      departureCity: departureCity ?? this.departureCity,
      destinationCity: destinationCity ?? this.destinationCity,
      vehicleType: vehicleType ?? this.vehicleType,
      loadingType: loadingType ?? this.loadingType,
      weightFrom: weightFrom ?? this.weightFrom,
      weightTo: weightTo ?? this.weightTo,
      volumeFrom: volumeFrom ?? this.volumeFrom,
      volumeTo: volumeTo ?? this.volumeTo,
      createdDate: createdDate ?? this.createdDate,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final params = <String, dynamic>{};

    void addString(String key, String value) {
      final normalized = value.trim();
      if (normalized.isNotEmpty) {
        params[key] = normalized;
      }
    }

    void addNumber(String key, double? value) {
      if (value != null) {
        params[key] = value.toString();
      }
    }

    addString('departure_city', departureCity);
    addString('destination_city', destinationCity);
    addString('vehicle_query', vehicleType);
    addString('loading_query', loadingType);
    addNumber('weight_min', weightFrom);
    addNumber('weight_max', weightTo);
    addNumber('volume_min', volumeFrom);
    addNumber('volume_max', volumeTo);
    if (createdDate != null) {
      params['created_date'] =
          '${createdDate!.year.toString().padLeft(4, '0')}-'
          '${createdDate!.month.toString().padLeft(2, '0')}-'
          '${createdDate!.day.toString().padLeft(2, '0')}';
    }
    return params;
  }
}
