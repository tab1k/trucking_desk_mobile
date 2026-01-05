
class PaymentModel {
  final int id;
  final String orderId;
  final String amount;
  final String status;
  final String? redirectUrl;

  PaymentModel({
    required this.id,
    required this.orderId,
    required this.amount,
    required this.status,
    this.redirectUrl,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] as int,
      orderId: json['order_id'] as String,
      amount: json['amount'].toString(),
      status: json['status'] as String,
      redirectUrl: json['redirect_url'] as String?,
    );
  }
}
