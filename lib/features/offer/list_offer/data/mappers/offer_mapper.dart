import '../../domain/entities/offer_entity.dart';
import '../../../../product/list_product/data/mappers/product_mapper.dart';
import '../models/offer_model.dart';

extension OfferMapper on OfferModel {
  OfferEntity toDomain() {
    return OfferEntity(
      id: id,
      shortDescription: shortDescription,
      longDescription: longDescription,
      products: products.map((p) => p.toDomain()).toList(),
      startDate: startDate,
      endDate: endDate,
      discountType: discountType,
      discountValue: discountValue,
    );
  }
}

extension OfferListMapper on List<OfferModel> {
  List<OfferEntity> toDomain() {
    return map((m) => m.toDomain()).toList();
  }
}
