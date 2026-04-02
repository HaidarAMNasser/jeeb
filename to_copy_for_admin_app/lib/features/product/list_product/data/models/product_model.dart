import 'product_image_model.dart';

class ProductModel {
  final String id;
  final String name;
  final String? description;
  final String? shortDescription;
  final int price;
  final int? priceAfterDiscount;
  final int? finalPrice;
  final String? restaurantId;
  final String? categoryId;
  final String? categoryName;
  final int? discount;
  final String? discountType;
  final bool? hasStock;
  final int? stockQuantity;
  final bool? isAvailable;
  final bool? isExternal;
  final String? externalProvider;
  final String? externalId;
  final String? merchantId;
  final String? merchantName;
  final String? merchantAddress;
  final String? merchantPhone;
  final bool hidePhoneNumber;
  final String? merchantEmail;
  final int? personCount;
  final double? commissionRate;
  final int? commissionAmount;
  final bool? commissionConfirmed;
  final bool? isFavorite;
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
    this.finalPrice,
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
    this.merchantName,
    this.merchantAddress,
    this.merchantPhone,
    this.hidePhoneNumber = false,
    this.merchantEmail,
    this.personCount,
    this.commissionRate,
    this.commissionAmount,
    this.commissionConfirmed,
    this.isFavorite,
    required this.images,
    this.rating,
    this.createdAt,
    this.updatedAt,
  });

  static String? _stringFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isEmpty ? null : value;
    if (value is Map) {
      if (value.isEmpty) return null;
    }
    return value.toString();
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Nested category (details response)
    String? categoryId = json['categoryId']?.toString();
    String? categoryName = json['categoryName']?.toString();
    final cat = json['category'];
    if (cat is Map<String, dynamic>) {
      categoryId ??= cat['id']?.toString();
      categoryName ??= cat['name']?.toString();
    }

    // Nested merchant (details response)
    String? merchantName;
    String? merchantAddress;
    String? merchantPhone;
    String? merchantEmail;
    bool hidePhoneNumber = false;
    final mer = json['merchant'];
    if (mer is Map<String, dynamic>) {
      final first = mer['firstName']?.toString() ?? '';
      final last = mer['lastName']?.toString() ?? '';
      merchantName = '$first $last'.trim().isEmpty ? null : '$first $last'.trim();
      merchantAddress = mer['address']?.toString();
      merchantPhone = mer['phone']?.toString();
      merchantEmail = mer['email']?.toString();
      hidePhoneNumber = mer['hidePhoneNumber'] == true;
    }
    // Flat merchant fields (orders/list responses)
    merchantName ??= _stringFromJson(json['merchantName']);
    merchantAddress ??= _stringFromJson(json['merchantAddress']);
    merchantPhone ??= _stringFromJson(json['merchantPhone']);
    merchantEmail ??= _stringFromJson(json['merchantEmail']);
    hidePhoneNumber = hidePhoneNumber || json['hidePhoneNumber'] == true;

    return ProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: _stringFromJson(json['description']),
      shortDescription: _stringFromJson(json['shortDescription']),
      price: json['price'] is num ? (json['price'] as num).toInt() : 0,
      priceAfterDiscount: json['priceAfterDiscount'] is num ? (json['priceAfterDiscount'] as num).toInt() : null,
      finalPrice: json['finalPrice'] is num ? (json['finalPrice'] as num).toInt() : null,
      restaurantId: json['restaurantId']?.toString(),
      categoryId: categoryId,
      categoryName: categoryName,
      discount: json['discount'] is num ? (json['discount'] as num).toInt() : null,
      discountType: json['discountType']?.toString(),
      hasStock: json['hasStock'] as bool?,
      stockQuantity: json['stockQuantity'] is num ? (json['stockQuantity'] as num).toInt() : null,
      isAvailable: json['isAvailable'] as bool?,
      isExternal: json['isExternal'] as bool?,
      externalProvider: json['externalProvider']?.toString(),
      externalId: json['externalId']?.toString(),
      merchantId: json['merchantId']?.toString(),
      merchantName: merchantName,
      merchantAddress: merchantAddress,
      merchantPhone: merchantPhone,
      hidePhoneNumber: hidePhoneNumber,
      merchantEmail: merchantEmail,
      personCount: json['personCount'] is num ? (json['personCount'] as num).toInt() : null,
      commissionRate: json['commissionRate'] is num ? (json['commissionRate'] as num).toDouble() : null,
      commissionAmount: json['commissionAmount'] is num ? (json['commissionAmount'] as num).toInt() : null,
      commissionConfirmed: json['commissionConfirmed'] as bool?,
      isFavorite: json['isFavorite'] as bool?,
      images: json['images'] != null
          ? (json['images'] as List)
              .map((item) => ProductImageModel.fromJson(item as Map<String, dynamic>))
              .toList()
          : [],
      rating: json['rating'] != null ? (json['rating'] as num).toDouble() : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
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
      'finalPrice': finalPrice,
      'restaurantId': restaurantId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'discount': discount,
      'discountType': discountType,
      'hasStock': hasStock,
      'stockQuantity': stockQuantity,
      'isAvailable': isAvailable,
      'merchantId': merchantId,
      'merchantName': merchantName,
      'merchantAddress': merchantAddress,
      'merchantPhone': merchantPhone,
      'hidePhoneNumber': hidePhoneNumber,
      'merchantEmail': merchantEmail,
      'personCount': personCount,
      'commissionRate': commissionRate,
      'commissionAmount': commissionAmount,
      'commissionConfirmed': commissionConfirmed,
      'isFavorite': isFavorite,
      'images': images.map((img) => img.toJson()).toList(),
      'rating': rating,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

