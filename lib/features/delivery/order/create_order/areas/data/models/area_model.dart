class AreaModel {
  final String id;
  final String name;
  final String? description;
  final int price;

  AreaModel({
    required this.id,
    required this.name,
    this.description,
    required this.price,
  });

  static String? _stringFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is Map) {
      if (value.isEmpty) return null;
    }
    return value.toString();
  }

  factory AreaModel.fromJson(Map<String, dynamic> json) {
    return AreaModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: _stringFromJson(json['description']),
      price: json['price'] is num ? (json['price'] as num).toInt() : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
    };
  }
}
