class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.isSubscriptionActive,
    required this.referralCode,
    required this.dateJoined,
  });

  final int id;
  final String username;
  final String? email;
  final String role;
  final String phoneNumber;
  final bool isSubscriptionActive;
  final String? referralCode;
  final DateTime? dateJoined;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String?,
      role: json['role'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      isSubscriptionActive: json['is_subscription_active'] as bool? ?? false,
      referralCode: json['referral_code'] as String?,
      dateJoined: json['date_joined'] != null
          ? DateTime.tryParse(json['date_joined'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'phone_number': phoneNumber,
      'is_subscription_active': isSubscriptionActive,
      'referral_code': referralCode,
      'date_joined': dateJoined?.toIso8601String(),
    };
  }
}
