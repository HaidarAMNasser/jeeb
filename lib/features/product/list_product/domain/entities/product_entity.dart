import 'package:equatable/equatable.dart';
import 'product_image_entity.dart';
class ProductEntity extends Equatable {
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

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        shortDescription,
        price,
        priceAfterDiscount,
        restaurantId,
        categoryId,
        categoryName,
        discount,
        discountType,
        hasStock,
        stockQuantity,
        isAvailable,
        isExternal,
        externalProvider,
        externalId,
        merchantId,
        images,
        rating,
        createdAt,
        updatedAt,
      ];
}

