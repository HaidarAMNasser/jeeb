import 'product_image_model.dart';

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final String? shortDescription;
  final int price; // Price in smallest currency unit (e.g., 1299 for 12.99)
  final int? priceAfterDiscount;
  final String? restaurantId;
  final String? categoryId;
  final String? categoryName;
  final int? discount;
  final String? discountType; // 'PERCENTAGE' or 'FIXED'
  final bool? hasStock;
  final int? stockQuantity;
  final bool? isAvailable;
  final bool? isExternal;
  final String? externalProvider;
  final String? externalId;
  final String? merchantId;
  final List<ProductImageModel> images;
  final double? rating;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    this.description,
    this.shortDescription,
    required this.price,
    this.priceAfterDiscount,
    this.restaurantId,
    this.categoryId,
    this.categoryName,
    this.discount,
    this.discountType,
    this.hasStock,
    this.stockQuantity,
    this.isAvailable,
    this.isExternal,
    this.externalProvider,
    this.externalId,
    this.merchantId,
    required this.images,
    this.rating,
    this.createdAt,
    this.updatedAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      shortDescription: json['shortDescription']?.toString(),
      price: json['price'] as int? ?? 0,
      priceAfterDiscount: json['priceAfterDiscount'] as int?,
      restaurantId: json['restaurantId']?.toString(),
      categoryId: json['categoryId']?.toString(),
      categoryName: json['categoryName']?.toString(),
      discount: json['discount'] as int?,
      discountType: json['discountType']?.toString(),
      hasStock: json['hasStock'] as bool?,
      stockQuantity: json['stockQuantity'] as int?,
      isAvailable: json['isAvailable'] as bool?,
      isExternal: json['isExternal'] as bool?,
      externalProvider: json['externalProvider']?.toString(),
      externalId: json['externalId']?.toString(),
      merchantId: json['merchantId']?.toString(),
      images: json['images'] != null
          ? (json['images'] as List)
              .map((item) => ProductImageModel.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'shortDescription': shortDescription,
      'price': price,
      'priceAfterDiscount': priceAfterDiscount,
      'restaurantId': restaurantId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'discount': discount,
      'discountType': discountType,
      'hasStock': hasStock,
      'stockQuantity': stockQuantity,
      'isAvailable': isAvailable,
      'isExternal': isExternal,
      'externalProvider': externalProvider,
      'externalId': externalId,
      'merchantId': merchantId,
      'images': images.map((img) => img.toJson()).toList(),
      'rating': rating,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

