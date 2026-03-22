import '../../../../country/data/models/country_model.dart';
import '../../../../city/data/models/city_model.dart';

class MerchantImageModel {
  final int id;
  final String url;
  final String mobileUrl;
  final String thumbnailUrl;
  final bool isMain;

  MerchantImageModel({
    required this.id,
    required this.url,
    required this.mobileUrl,
    required this.thumbnailUrl,
    required this.isMain,
  });

  factory MerchantImageModel.fromJson(Map<String, dynamic> json) {
    return MerchantImageModel(
      id: json['id'] as int? ?? 0,
      url: json['url']?.toString() ?? '',
      mobileUrl: json['mobileUrl']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      isMain: json['isMain'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'mobileUrl': mobileUrl,
      'thumbnailUrl': thumbnailUrl,
      'isMain': isMain,
    };
  }
}

class MerchantModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String? role;
  final String? notificationChannel;
  final int? countryId;
  final int? cityId;
  final String? address;
  final String? birthday;
  final bool? isOnline;
  final String? verifiedAt;
  final String? createdAt;
  final String? updatedAt;
  final MerchantImageModel? image;
  final CountryModel? country;
  final CityModel? city;

  MerchantModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    this.role,
    this.notificationChannel,
    this.countryId,
    this.cityId,
    this.address,
    this.birthday,
    this.isOnline,
    this.verifiedAt,
    this.createdAt,
    this.updatedAt,
    this.image,
    this.country,
    this.city,
  });

  factory MerchantModel.fromJson(Map<String, dynamic> json) {
    final firstName =
        json['restaurantName']?.toString() ??
        json['storeName']?.toString() ??
        json['name']?.toString() ??
        json['firstName']?.toString() ??
        '';
    final lastName = json['lastName']?.toString() ?? '';

    return MerchantModel(
      id: json['id']?.toString() ?? '',
      firstName: firstName,
      lastName: lastName,
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString(),
      notificationChannel: json['notificationChannel']?.toString(),
      countryId: json['countryId'] as int?,
      cityId: json['cityId'] as int?,
      address: json['address']?.toString(),
      birthday: json['birthday']?.toString(),
      isOnline: json['isOnline'] as bool?,
      verifiedAt: json['verifiedAt']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      image: json['image'] != null
          ? MerchantImageModel.fromJson(json['image'] as Map<String, dynamic>)
          : null,
      country: json['country'] != null
          ? CountryModel.fromJson(json['country'] as Map<String, dynamic>)
          : null,
      city: json['city'] != null
          ? CityModel.fromJson(json['city'] as Map<String, dynamic>)
          : null,
    );
  }

  // Helper getters for backward compatibility
  String get name => '$firstName $lastName'.trim();
  String? get cityName => city?.name.en.isNotEmpty == true
      ? city?.name.en
      : (city?.name.ar.isNotEmpty == true ? city?.name.ar : null);
  String? get countryName => country?.name.en.isNotEmpty == true
      ? country?.name.en
      : (country?.name.ar.isNotEmpty == true ? country?.name.ar : null);
  String? get phoneNumber => phone;
  String? get imageUrl => image?.url;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'notificationChannel': notificationChannel,
      'countryId': countryId,
      'cityId': cityId,
      'address': address,
      'birthday': birthday,
      'isOnline': isOnline,
      'verifiedAt': verifiedAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'image': image?.toJson(),
      'country': country?.toJson(),
      'city': city?.toJson(),
    };
  }
}

