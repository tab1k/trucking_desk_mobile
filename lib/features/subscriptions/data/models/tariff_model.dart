class TariffModel {
  const TariffModel({
    required this.code,
    required this.title,
    required this.price,
    required this.description,
    required this.features,
    required this.isActive,
    this.cssClass,
  });

  final String code;
  final String title;
  final double price;
  final String description;
  final List<String> features;
  final bool isActive;
  final String? cssClass;

  factory TariffModel.fromJson(Map<String, dynamic> json) {
    return TariffModel(
      code: json['code'] as String? ?? '',
      title: json['title'] as String? ?? '',
      price: _toDouble(json['price']) ?? 0.0,
      description: json['description'] as String? ?? '',
      features: (json['features'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isActive: json['is_active'] as bool? ?? false,
      cssClass: json['css_class'] as String?,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
