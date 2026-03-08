import '../../domain/entities/offer_entity.dart';
import '../models/offer_model.dart';

extension OfferMapper on OfferModel {
  OfferEntity toDomain() {
    return OfferEntity(
      id: id,
      name: name,
      description: description,
      discountType: discountType == 'percentage'
          ? DiscountType.PERCENTAGE
          : DiscountType.FIXED,
      discountValue: discountValue,
      startDate: startDate,
      endDate: endDate,
      isActive: isActive,
      merchantId: merchantId,
      createdAt: createdAt,
      updatedAt: updatedAt,
      products: products.map((product) => product.toDomain()).toList(),
      merchant: merchant.toDomain(),
    );
  }
}

extension OfferListMapper on List<OfferModel> {
  List<OfferEntity> toDomain() {
    return map((model) => model.toDomain()).toList();
  }
}
