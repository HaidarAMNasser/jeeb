import 'package:equatable/equatable.dart';
import 'product_image_entity.dart';

class ProductEntity extends Equatable {
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
  final String? merchantEmail;
  final int? personCount;
  final double? commissionRate;
  final int? commissionAmount;
  final bool? commissionConfirmed;
  final bool? isFavorite;
  final List<ProductImageEntity> images;
  final double? rating;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProductEntity({
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

  /// Display price: finalPrice if set, else priceAfterDiscount, else price.
  int get displayPrice => finalPrice ?? priceAfterDiscount ?? price;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        shortDescription,
        price,
        priceAfterDiscount,
        finalPrice,
        restaurantId,
        categoryId,
        categoryName,
        discount,
        discountType,
        hasStock,
        stockQuantity,
        isAvailable,
        merchantId,
        merchantName,
        merchantAddress,
        merchantPhone,
        merchantEmail,
        personCount,
        commissionRate,
        commissionAmount,
        commissionConfirmed,
        isFavorite,
        images,
        rating,
        createdAt,
        updatedAt,
      ];
}

