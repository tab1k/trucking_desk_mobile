class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.isSubscriptionActive,
    this.balance = 0,
    required this.referralCode,
    required this.dateJoined,
    this.avatar,
    this.verificationStatus,
    this.verificationRejectionReason,
  });

  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String? middleName;
  final String? email;
  final String? avatar;
  final String role;
  final String phoneNumber;
  final bool isSubscriptionActive;
  final double balance;
  final String? referralCode;
  final DateTime? dateJoined;
  final String? verificationStatus;
  final String? verificationRejectionReason;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    double parseBalance(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      middleName: json['middle_name'] as String?,
      email: json['email'] as String?,
      avatar: _parseAvatar(json),
      role: json['role'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      isSubscriptionActive: json['is_subscription_active'] as bool? ?? false,
      balance: parseBalance(json['balance']),
      referralCode: json['referral_code'] as String?,
      dateJoined:
          json['date_joined'] != null
              ? DateTime.tryParse(json['date_joined'] as String)
              : null,
      verificationStatus: json['verification_status'] as String?,
      verificationRejectionReason: json['verification_rejection_reason'] as String?,
    );
  }

  static String? _parseAvatar(Map<String, dynamic> json) {
    final raw =
        json['avatar'] ??
        json['avatar_url'] ??
        json['photo'] ??
        json['photo_url'];
    if (raw is String && raw.isNotEmpty) return raw;
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'middle_name': middleName,
      'email': email,
      'avatar': avatar,
      'role': role,
      'phone_number': phoneNumber,
      'is_subscription_active': isSubscriptionActive,
      'balance': balance,
      'referral_code': referralCode,
      'date_joined': dateJoined?.toIso8601String(),
      'verification_status': verificationStatus,
      'verification_rejection_reason': verificationRejectionReason,
    };
  }

  String get fullName {
    final parts = [
      firstName.trim(),
      lastName.trim(),
    ].where((part) => part.isNotEmpty).toList(growable: false);
    return parts.join(' ');
  }

  String get displayName => fullName.isNotEmpty ? fullName : username;
}
