/// Lightweight model for a product returned by GET /favorites (id, name, price, category).
class FavoriteProductModel {
  final String id;
  final String name;
  final int price;
  final String? categoryName;

  FavoriteProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.categoryName,
  });

  factory FavoriteProductModel.fromJson(Map<String, dynamic> json) {
    return FavoriteProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: json['price'] is num ? (json['price'] as num).toInt() : 0,
      categoryName: json['category']?.toString(),
    );
  }
}
