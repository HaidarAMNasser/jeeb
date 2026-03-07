import '../../domain/entities/user_entity.dart';
import 'package:jeeb_app/features/country/data/models/country_model.dart';
import 'package:jeeb_app/features/city/data/models/city_model.dart';

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
  final String? verifiedAt;
  final double? currentLat;
  final double? currentLng;
  final int countryId;
  final CountryModel? country;
  final int cityId;
  final CityModel? city;
  final String createdAt;
  final String updatedAt;

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
    this.verifiedAt,
    this.currentLat,
    this.currentLng,
    required this.countryId,
    this.country,
    required this.cityId,
    this.city,
    required this.createdAt,
    required this.updatedAt,
  });

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
      verifiedAt: json['verifiedAt'] as String?,
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
    );
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
      'verifiedAt': verifiedAt,
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
      verifiedAt: verifiedAt != null ? DateTime.tryParse(verifiedAt!) : null,
      currentLat: currentLat,
      currentLng: currentLng,
      countryId: countryId,
      country: country?.toDomain(),
      cityId: cityId,
      city: city?.toDomain(),
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
    );
  }
}

