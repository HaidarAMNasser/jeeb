import '../../domain/entities/merchant_entity.dart';
import '../models/merchant_model.dart';

extension MerchantMapper on MerchantModel {
  MerchantEntity toDomain() {
    return MerchantEntity(
      id: id,
      // name: name,
      restaurantName: restaurantName,
      email: email,
      cityName: cityName,
      countryName: countryName,
      location: address,
      phoneNumber: phoneNumber,
      hidePhoneNumber: hidePhoneNumber,
      image: imageUrl,
      isOnline: isOnline,
    );
  }
}

extension MerchantListMapper on List<MerchantModel> {
  List<MerchantEntity> toDomain() {
    return map((model) => model.toDomain()).toList();
  }
}

