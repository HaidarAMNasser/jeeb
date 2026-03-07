import '../../domain/entities/product_entity.dart';
import '../../domain/entities/product_image_entity.dart';
import '../models/product_model.dart';
import '../models/product_image_model.dart';

extension ProductImageMapper on ProductImageModel {
  ProductImageEntity toDomain() {
    return ProductImageEntity(
      id: id,
      url: url,
      mobileUrl: mobileUrl,
      thumbnailUrl: thumbnailUrl,
      isMain: isMain,
      displayOrder: displayOrder,
    );
  }
}

extension ProductImageListMapper on List<ProductImageModel> {
  List<ProductImageEntity> toDomain() {
    return map((model) => model.toDomain()).toList();
  }
}

extension ProductMapper on ProductModel {
  ProductEntity toDomain() {
    return ProductEntity(
      id: id,
      name: name,
      description: description,
      shortDescription: shortDescription,
      price: price,
      priceAfterDiscount: priceAfterDiscount,
      restaurantId: restaurantId,
      categoryId: categoryId ?? '',
      categoryName: categoryName ?? '',
      discount: discount,
      discountType: discountType,
      hasStock: hasStock,
      stockQuantity: stockQuantity,
      isAvailable: isAvailable,
      isExternal: isExternal,
      externalProvider: externalProvider,
      externalId: externalId,
      merchantId: merchantId,
      images: images.map((img) => img.toDomain()).toList(),
      rating: rating,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension ProductListMapper on List<ProductModel> {
  List<ProductEntity> toDomain() {
    return map((model) => model.toDomain()).toList();
  }
}

