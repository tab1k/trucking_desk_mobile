class PendingReview {
  final String orderId;
  final String driverName;
  final String cargoName;

  const PendingReview({
    required this.orderId,
    required this.driverName,
    required this.cargoName,
  });

  factory PendingReview.fromJson(Map<String, dynamic> json) {
    return PendingReview(
      orderId: (json['order_id'] ?? '').toString(),
      driverName: (json['driver_name'] as String?) ?? '',
      cargoName: (json['cargo_name'] as String?) ?? '',
    );
  }
}
