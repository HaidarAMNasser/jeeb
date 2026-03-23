import 'package:equatable/equatable.dart';

class MerchantEntity extends Equatable {
  final String id;
  // final String name;
  final String restaurantName;
  final String email;
  final String? cityName;
  final String? countryName;
  final String? location; // Not used in UI right now
  final String? phoneNumber;
  /// When true, merchant chose to hide phone from customers (API: `hidePhoneNumber`).
  final bool hidePhoneNumber;
  final String? image; // Might be null
  final bool? isOnline;

  const MerchantEntity({
    required this.id,
    // required this.name,
    required this.restaurantName,
    required this.email,
    this.cityName,
    this.countryName,
    this.location,
    this.phoneNumber,
    this.hidePhoneNumber = false,
    this.image,
    this.isOnline,
  });

  /// Show phone row only when we have a number and merchant did not hide it.
  bool get shouldShowPhone =>
      phoneNumber != null &&
      phoneNumber!.trim().isNotEmpty &&
      !hidePhoneNumber;

  @override
  List<Object?> get props => [
        id,
        // name,
        restaurantName,
        email,
        cityName,
        countryName,
        location,
        phoneNumber,
        hidePhoneNumber,
        image,
        isOnline,
      ];
}

