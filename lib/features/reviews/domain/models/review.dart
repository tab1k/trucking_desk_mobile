class Review {
  final String id;
  final String orderId;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String senderName;
  final String? senderPhoto;

  const Review({
    required this.id,
    required this.orderId,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.senderName,
    this.senderPhoto,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: (json['id'] ?? '').toString(),
      orderId: (json['order_id'] ?? '').toString(),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      comment: (json['comment'] as String?) ?? '',
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      senderName: (json['sender_name'] as String?) ?? 'Аноним',
      senderPhoto: json['sender_photo'] as String?,
    );
  }
}
