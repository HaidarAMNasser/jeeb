import '../../domain/entities/offer_entity.dart';
import '../../../../merchant/merchant_details/data/mappers/merchant_mapper.dart';
import '../../../../product/list_product/data/mappers/product_mapper.dart';
import '../models/offer_model.dart';

extension OfferMapper on OfferModel {
  OfferEntity toDomain() {
    return OfferEntity(
      id: id,
      name: name,
      description: description,
      shortDescription: shortDescription,
      longDescription: longDescription,
      merchant: merchant?.toDomain(),
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
