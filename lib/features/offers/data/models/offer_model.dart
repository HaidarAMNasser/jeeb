import '../../domain/entities/offer_entity.dart';

class OfferModel {
  final String id;
  final String name;
  final String description;
  final String discountType;
  final double discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String merchantId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OfferProductModel> products;
  final OfferMerchantModel merchant;

  OfferModel({
    required this.id,
    required this.name,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.merchantId,
    required this.createdAt,
    required this.updatedAt,
    this.products = const [],
    required this.merchant,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      discountType: json['discountType']?.toString() ?? 'PERCENTAGE',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.parse(json['startDate']),
      endDate: DateTime.parse(json['endDate']),
      isActive: json['isActive'] as bool? ?? true,
      merchantId: json['merchantId']?.toString() ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      products: (json['products'] as List?)
          ?.map((e) => OfferProductModel.fromJson(e))
          .toList() ?? [],
      merchant: OfferMerchantModel.fromJson(json['merchant'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'merchantId': merchantId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'products': products.map((e) => e.toJson()).toList(),
      'merchant': merchant.toJson(),
    };
  }

  OfferEntity toDomain() {
    return OfferEntity(
      id: id,
      name: name,
      description: description,
      discountType: discountType == 'PERCENTAGE' ? DiscountType.PERCENTAGE : DiscountType.FIXED,
      discountValue: discountValue,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      merchantId: merchantId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      products: products.map((e) => e.toDomain()).toList(),
      merchant: merchant.toDomain(),
    );
  }
}

class OfferProductModel {
  final String id;
  final String name;
  final double price;
  final double? offerPrice;

  OfferProductModel({
    required this.id,
    required this.name,
    required this.price,
    this.offerPrice,
  });

  factory OfferProductModel.fromJson(Map<String, dynamic> json) {
    return OfferProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      offerPrice: (json['offerPrice'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'offerPrice': offerPrice,
    };
  }

  OfferProductEntity toDomain() {
    return OfferProductEntity(
      id: id,
      name: name,
      price: price,
      offerPrice: offerPrice,
    );
  }
}

class OfferMerchantModel {
  final String id;
  final String restaurantName;

  OfferMerchantModel({
    required this.id,
    required this.restaurantName,
  });

  factory OfferMerchantModel.fromJson(Map<String, dynamic> json) {
    return OfferMerchantModel(
      id: json['id']?.toString() ?? '',
      restaurantName: json['restaurantName']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'restaurantName': restaurantName,
    };
  }

  OfferMerchantEntity toDomain() {
    return OfferMerchantEntity(
      id: id,
      restaurantName: restaurantName,
    );
  }
}
