import '../../domain/entities/merchant_entity.dart';
import '../models/merchant_model.dart';

extension MerchantMapper on MerchantModel {
  MerchantEntity toDomain() {
    return MerchantEntity(
      id: id,
      name: name, // firstName + lastName
      email: email,
      cityName: cityName, // from city.nameEn or city.nameAr
      countryName: countryName, // from country.nameEn or country.nameAr
      location: address,
      phoneNumber: phoneNumber, // from phone
      image: imageUrl, // from image.url
    );
  }
}

extension MerchantListMapper on List<MerchantModel> {
  List<MerchantEntity> toDomain() {
    return map((model) => model.toDomain()).toList();
  }
}

