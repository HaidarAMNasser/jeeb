import 'package:equatable/equatable.dart';

class MerchantEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? cityName;
  final String? countryName;
  final String? location; // Not used in UI right now
  final String? phoneNumber;
  final String? image; // Might be null
  final bool? isOnline;

  const MerchantEntity({
    required this.id,
    required this.name,
    required this.email,
    this.cityName,
    this.countryName,
    this.location,
    this.phoneNumber,
    this.image,
    this.isOnline,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        cityName,
        countryName,
        location,
        phoneNumber,
        image,
        isOnline,
      ];
}

