import 'package:equatable/equatable.dart';
import 'package:jeeb_app/features/city/domain/entities/city_entity.dart';
import 'package:jeeb_app/features/country/domain/entities/country_entity.dart';

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
  final bool? isActive;
  final DateTime? verifiedAt;
  final bool isVerified;
  final double? currentLat;
  final double? currentLng;
  final int countryId;
  final CountryEntity? country;
  final int cityId;
  final CityEntity? city;
  final DateTime createdAt;
  final DateTime updatedAt;
  /// Profile image URL from backend (user.image.url / thumbnailUrl / mobileUrl). May be relative.
  final String? profileImageUrl;

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
    this.profileImageUrl,
  });

  String get fullName => '$firstName $lastName';

  /// Shadow guest accounts use `guest-{uid}@jeeb.local` (Guest_API).
  bool get isGuest {
    final value = email.trim().toLowerCase();
    return value.startsWith('guest-') && value.endsWith('@jeeb.local');
  }

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
        isActive,
        verifiedAt,
        isVerified,
        currentLat,
        currentLng,
        countryId,
        country,
        cityId,
        city,
        createdAt,
        updatedAt,
        profileImageUrl,
      ];
}

