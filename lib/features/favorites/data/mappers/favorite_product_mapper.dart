import 'package:jeeb_app/features/favorites/data/models/favorite_product_model.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_image_entity.dart';

extension FavoriteProductMapper on FavoriteProductModel {
  /// Map to ProductEntity for reuse in ProductListItem (images empty).
  ProductEntity toProductEntity() {
    return ProductEntity(
      id: id,
      name: name,
      price: price,
      priceAfterDiscount: price,
      categoryName: categoryName,
      images: const <ProductImageEntity>[],
    );
  }
}
