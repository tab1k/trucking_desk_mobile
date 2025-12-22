class OrderBidInfo {
  const OrderBidInfo({
    required this.id,
    required this.driverId,
    required this.driverName,
    this.driverPhone = '',
    this.amount,
    this.status = '',
    this.statusLabel = '',
    this.comment = '',
    this.createdAt,
  });

  final String id;
  final String driverId;
  final String driverName;
  final String driverPhone;
  final double? amount;
  final String status;
  final String statusLabel;
  final String comment;
  final DateTime? createdAt;

  static OrderBidInfo fromJson(Map<String, dynamic> json) {
    return OrderBidInfo(
      id: (json['id'] ?? '').toString(),
      driverId: (json['driver'] ?? '').toString(),
      driverName:
          (json['driver_full_name'] as String?)?.trim() ??
          (json['driver_phone_number'] as String?)?.trim() ??
          'Водитель',
      driverPhone: (json['driver_phone_number'] as String?)?.trim() ?? '',
      amount: _parseNum(json['amount'])?.toDouble(),
      status: (json['status'] as String?) ?? '',
      statusLabel: (json['status_display'] as String?) ?? '',
      comment: (json['comment'] as String?)?.trim() ?? '',
      createdAt: _parseDate(json['created_at'] as String?),
    );
  }
}

double? _parseNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String && value.isNotEmpty) {
    return double.tryParse(value);
  }
  return null;
}

DateTime? _parseDate(dynamic value) {
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
