import 'package:equatable/equatable.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';

/// Geo point for restaurant/owner location on order `owner.location`.
class OrderOwnerLocationEntity extends Equatable {
  final double? lat;
  final double? lng;

  const OrderOwnerLocationEntity({this.lat, this.lng});

  @override
  List<Object?> get props => [lat, lng];
}

/// Merchant (restaurant owner) embedded on order responses.
class OrderOwnerEntity extends Equatable {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? address;
  final String? restaurantName;
  final OrderOwnerLocationEntity? location;

  const OrderOwnerEntity({
    required this.id,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.address,
    this.restaurantName,
    this.location,
  });

  String get fullName {
    final f = firstName ?? '';
    final l = lastName ?? '';
    return '$f $l'.trim();
  }

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        phone,
        email,
        address,
        restaurantName,
        location,
      ];
}

class OrderEntity extends Equatable {
  final String id;
  final List<ProductEntity> products;
  final DeliveryManEntity? deliveryMan;
  final DateTime? date;
  final double? longitude;
  final double? latitude;
  final int? numberOfPeople;
  final String? status;
  final String? merchantId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? pickupAddress;
  final String? deliveryAddress;
  final String? distance;
  final String? customerName;
  final String? customerPhone;
  final double? totalPrice;
  final double? deliveryFee;
  final double? deliveryEarning;
  final int? preparationTime;
  final String? merchantPhone;
  final bool? hideMerchantPhone;
  final OrderOwnerEntity? owner;

  const OrderEntity({
    required this.id,
    required this.products,
    this.deliveryMan,
    this.date,
    this.longitude,
    this.latitude,
    this.numberOfPeople,
    this.status,
    this.merchantId,
    this.createdAt,
    this.updatedAt,
    this.pickupAddress,
    this.deliveryAddress,
    this.distance,
    this.customerName,
    this.customerPhone,
    this.totalPrice,
    this.deliveryFee,
    this.deliveryEarning,
    this.preparationTime,
    this.merchantPhone,
    this.hideMerchantPhone,
    this.owner,
  });

  @override
  List<Object?> get props => [
    id,
    products,
    deliveryMan,
    date,
    longitude,
    latitude,
    numberOfPeople,
    status,
    merchantId,
    createdAt,
    updatedAt,
    pickupAddress,
    deliveryAddress,
    distance,
    customerName,
    customerPhone,
    totalPrice,
    deliveryFee,
    deliveryEarning,
    preparationTime,
    merchantPhone,
    hideMerchantPhone,
    owner,
  ];
}

class DeliveryManEntity extends Equatable {
  final String id;
  final String name; // firstName + lastName
  final String phone;
  final String email;
  final String? cityName;
  final String? countryName;
  final String? image;
  final bool? isOnline;
  final int? officeOwnerId;

  const DeliveryManEntity({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.cityName,
    this.countryName,
    this.image,
    this.isOnline,
    this.officeOwnerId,
  });

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    email,
    cityName,
    countryName,
    image,
    isOnline,
    officeOwnerId,
  ];
}
