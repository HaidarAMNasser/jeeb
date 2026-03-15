import 'package:jeeb_app/features/city/data/models/city_model.dart';
import 'package:jeeb_app/features/country/data/models/country_model.dart';

import '../../domain/entities/user_entity.dart';

/// Profile image from backend (Auth_API: user.image = { id, url, mobileUrl, thumbnailUrl, isMain }).
class UserImageModel {
  final int id;
  final String url;
  final String mobileUrl;
  final String thumbnailUrl;
  final bool isMain;

  UserImageModel({
    required this.id,
    required this.url,
    required this.mobileUrl,
    required this.thumbnailUrl,
    this.isMain = true,
  });

  factory UserImageModel.fromJson(Map<String, dynamic> json) {
    return UserImageModel(
      id: json['id'] as int? ?? 0,
      url: json['url']?.toString() ?? '',
      mobileUrl: json['mobileUrl']?.toString() ?? '',
      thumbnailUrl: json['thumbnailUrl']?.toString() ?? '',
      isMain: json['isMain'] as bool? ?? true,
    );
  }
}

class UserModel {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String role;
  final String notificationChannel;
  final String? address;
  final bool? isOnline;
  final bool? isActive;
  final String? verifiedAt;
  final bool isVerified;
  final double? currentLat;
  final double? currentLng;
  final int countryId;
  final CountryModel? country;
  final int cityId;
  final CityModel? city;
  final String createdAt;
  final String updatedAt;
  final UserImageModel? image;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.role,
    required this.notificationChannel,
    this.address,
    this.isOnline,
    this.isActive,
    this.verifiedAt,
    this.isVerified = false,
    this.currentLat,
    this.currentLng,
    required this.countryId,
    this.country,
    required this.cityId,
    this.city,
    required this.createdAt,
    required this.updatedAt,
    this.image,
  });

  static bool _parseIsVerified(Map<String, dynamic> json) {
    if (json['isVerified'] == true) return true;
    final verifiedAt = json['verifiedAt'];
    if (verifiedAt != null && verifiedAt.toString().trim().isNotEmpty) {
      return true;
    }
    final emailVerified = json['emailVerified'] == true;
    final mobileVerified = json['mobileVerified'] == true;
    return emailVerified && mobileVerified;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'CUSTOMER',
      notificationChannel: json['notificationChannel'] as String? ?? 'EMAIL',
      address: json['address'] as String?,
      isOnline: json['isOnline'] as bool?,
      isActive: json['isActive'] as bool?,
      verifiedAt: json['verifiedAt'] as String?,
      isVerified: _parseIsVerified(json),
      currentLat: json['currentLat'] != null
          ? (json['currentLat'] as num).toDouble()
          : null,
      currentLng: json['currentLng'] != null
          ? (json['currentLng'] as num).toDouble()
          : null,
      countryId: json['countryId'] as int? ?? 0,
      country: json['country'] != null
          ? CountryModel.fromJson(json['country'] as Map<String, dynamic>)
          : null,
      cityId: json['cityId'] as int? ?? 0,
      city: json['city'] != null
          ? CityModel.fromJson(json['city'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      image: json['image'] is Map<String, dynamic>
          ? UserImageModel.fromJson(json['image'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Best URL for profile avatar (thumbnail, then mobile, then full). May be relative; use assetsBaseUrl if needed.
  String? get profileImageUrl {
    if (image == null) return null;
    final u = image!.thumbnailUrl.isNotEmpty
        ? image!.thumbnailUrl
        : (image!.mobileUrl.isNotEmpty ? image!.mobileUrl : image!.url);
    return u.isNotEmpty ? u : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'role': role,
      'notificationChannel': notificationChannel,
      'address': address,
      'isOnline': isOnline,
      'isActive': isActive,
      'verifiedAt': verifiedAt,
      'isVerified': isVerified,
      'currentLat': currentLat,
      'currentLng': currentLng,
      'countryId': countryId,
      'country': country?.toJson(),
      'cityId': cityId,
      'city': city?.toJson(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  UserEntity toDomain() {
    UserRole userRole;
    switch (role.toUpperCase()) {
      case 'CUSTOMER':
        userRole = UserRole.customer;
        break;
      case 'DELIVERY':
        userRole = UserRole.delivery;
        break;
      case 'MERCHANT':
        userRole = UserRole.merchant;
        break;
      case 'ADMIN':
        userRole = UserRole.admin;
        break;
      default:
        userRole = UserRole.customer;
    }

    NotificationChannel channel;
    switch (notificationChannel.toUpperCase()) {
      case 'EMAIL':
        channel = NotificationChannel.email;
        break;
      case 'WHATSAPP':
        channel = NotificationChannel.whatsapp;
        break;
      default:
        channel = NotificationChannel.email;
    }

    return UserEntity(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
      role: userRole,
      notificationChannel: channel,
      address: address,
      isOnline: isOnline,
      isActive: isActive,
      verifiedAt: verifiedAt != null ? DateTime.tryParse(verifiedAt!) : null,
      isVerified: isVerified,
      currentLat: currentLat,
      currentLng: currentLng,
      countryId: countryId,
      country: country?.toDomain(),
      cityId: cityId,
      city: city?.toDomain(),
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
      profileImageUrl: profileImageUrl,
    );
  }
}
