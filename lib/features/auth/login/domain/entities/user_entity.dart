import 'package:equatable/equatable.dart';
import 'package:jeeb_app/features/country/domain/entities/country_entity.dart';
import 'package:jeeb_app/features/city/domain/entities/city_entity.dart';

enum UserRole {
  customer,
  delivery,
  merchant,
  admin,
}

enum NotificationChannel {
  email,
  whatsapp,
}

class UserEntity extends Equatable {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final UserRole role;
  final NotificationChannel notificationChannel;
  final String? address;
  final bool? isOnline;
  final DateTime? verifiedAt;
  final double? currentLat;
  final double? currentLng;
  final int countryId;
  final CountryEntity? country;
  final int cityId;
  final CityEntity? city;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserEntity({
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

  String get fullName => '$firstName $lastName';

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        phone,
        role,
        notificationChannel,
        address,
        isOnline,
        verifiedAt,
        currentLat,
        currentLng,
        countryId,
        country,
        cityId,
        city,
        createdAt,
        updatedAt,
      ];
}

