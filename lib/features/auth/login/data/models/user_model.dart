import 'package:jeeb_app/features/auth/domain/entities/user_entity.dart';

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
  final int cityId;
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
    required this.cityId,
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
      cityId: json['cityId'] as int? ?? 0,
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
      'cityId': cityId,
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
      cityId: cityId,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
    );
  }
}
