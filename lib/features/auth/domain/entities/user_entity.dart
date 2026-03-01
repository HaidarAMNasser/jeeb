import 'package:equatable/equatable.dart';

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
  final int cityId;
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
    required this.cityId,
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
        cityId,
        createdAt,
        updatedAt,
      ];
}
