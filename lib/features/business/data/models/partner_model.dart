class PartnerModel {
  const PartnerModel({
    required this.id,
    required this.companyName,
    required this.activityDisplay,
    required this.companyDescription,
    required this.countriesDisplay,
    required this.city,
    required this.phone,
    required this.email,
    required this.createdAt,
    this.logo,
  });

  final int id;
  final String companyName;
  final String activityDisplay;
  final String companyDescription;
  final String countriesDisplay;
  final String city;
  final String phone;
  final String email;
  final String? logo;
  final DateTime createdAt;

  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    return PartnerModel(
      id: json['id'] as int,
      companyName: json['company_name'] as String? ?? '',
      activityDisplay: json['activity_display'] as String? ?? '',
      companyDescription: json['company_description'] as String? ?? '',
      countriesDisplay: json['countries_display'] as String? ?? '',
      city: json['city'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      logo: json['logo'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
