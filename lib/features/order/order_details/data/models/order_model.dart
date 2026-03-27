import 'package:jeeb_app/features/city/data/models/city_model.dart';
import 'package:jeeb_app/features/country/data/models/country_model.dart';
import 'package:jeeb_app/features/product/list_product/data/models/product_model.dart';

class OrderModel {
  final String id;
  final List<ProductModel>? products;
  final DeliveryManModel? deliveryMan;
  final String? date;
  final double? longitude;
  final double? latitude;
  final int? numberOfPeople;
  final String? status;
  final String? merchantId;
  final String? createdAt;
  final String? updatedAt;
  final String? pickupAddress;
  final String? deliveryAddress;
  final String? distance;
  final String? customerName;
  final String? customerPhone;
  final double? totalPrice;
  final double? deliveryFee;
  final double? deliveryEarning;
  final int? preparationTime;

  OrderModel({
    required this.id,
    this.products,
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
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id']?.toString() ?? '',
      products: json['products'] != null
          ? (json['products'] as List)
                .map(
                  (item) => ProductModel.fromJson(item as Map<String, dynamic>),
                )
                .toList()
          : (json['items'] != null
                ? (json['items'] as List)
                      .map(
                        (item) =>
                            ProductModel.fromJson(item as Map<String, dynamic>),
                      )
                      .toList()
                : null),
      deliveryMan: json['deliveryMan'] != null
          ? DeliveryManModel.fromJson(
              json['deliveryMan'] as Map<String, dynamic>,
            )
          : null,
      date: json['date']?.toString(),
      longitude: json['longitude'] != null
          ? (json['longitude'] is num
                ? (json['longitude'] as num).toDouble()
                : double.tryParse(json['longitude'].toString()))
          : null,
      latitude: json['latitude'] != null
          ? (json['latitude'] is num
                ? (json['latitude'] as num).toDouble()
                : double.tryParse(json['latitude'].toString()))
          : null,
      numberOfPeople: json['numberOfPeople'] != null
          ? (json['numberOfPeople'] is int
                ? json['numberOfPeople'] as int
                : int.tryParse(json['numberOfPeople'].toString()))
          : null,
      status: json['status']?.toString(),
      merchantId: json['merchantId']?.toString(),
      createdAt: json['createdAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
      pickupAddress: json['pickup_address']?.toString(),
      deliveryAddress: json['delivery_address']?.toString(),
      distance: json['distance']?.toString(),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      totalPrice: json['total_price'] != null
          ? (json['total_price'] is num
                ? (json['total_price'] as num).toDouble()
                : double.tryParse(json['total_price'].toString()))
          : null,
      deliveryFee: json['delivery_fee'] != null
          ? (json['delivery_fee'] is num
                ? (json['delivery_fee'] as num).toDouble()
                : double.tryParse(json['delivery_fee'].toString()))
          : null,
      deliveryEarning: json['delivery_earning'] != null
          ? (json['delivery_earning'] is num
                ? (json['delivery_earning'] as num).toDouble()
                : double.tryParse(json['delivery_earning'].toString()))
          : null,
      preparationTime: json['preparation_time'] != null
          ? (json['preparation_time'] is int
                ? json['preparation_time'] as int
                : int.tryParse(json['preparation_time'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'products': products?.map((p) => p.toJson()).toList(),
      'deliveryMan': deliveryMan?.toJson(),
      'date': date,
      'longitude': longitude,
      'latitude': latitude,
      'numberOfPeople': numberOfPeople,
      'status': status,
      'merchantId': merchantId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'pickup_address': pickupAddress,
      'delivery_address': deliveryAddress,
      'distance': distance,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'total_price': totalPrice,
      'delivery_fee': deliveryFee,
      'delivery_earning': deliveryEarning,
      'preparation_time': preparationTime,
    };
  }
}

class DeliveryImageModel {
  final int id;
  final String url;
  final String mobileUrl;
  final String thumbnailUrl;
  final bool isMain;

  DeliveryImageModel({
    required this.id,
    required this.url,
    required this.mobileUrl,
    required this.thumbnailUrl,
    required this.isMain,
  });

  factory DeliveryImageModel.fromJson(Map<String, dynamic> json) {
    return DeliveryImageModel(
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

class DeliveryManModel {
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
  final DeliveryImageModel? image;
  final CountryModel? country;
  final CityModel? city;
  final int? officeOwnerId;

  DeliveryManModel({
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
    this.officeOwnerId,
  });

  factory DeliveryManModel.fromJson(Map<String, dynamic> json) {
    return DeliveryManModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
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
          ? DeliveryImageModel.fromJson(json['image'] as Map<String, dynamic>)
          : null,
      country: json['country'] != null
          ? CountryModel.fromJson(json['country'] as Map<String, dynamic>)
          : null,
      city: json['city'] != null
          ? CityModel.fromJson(json['city'] as Map<String, dynamic>)
          : null,
      officeOwnerId: json['officeOwnerId'] as int?,
    );
  }

  // Helper getters for backward compatibility
  String get name => '$firstName $lastName';
  String? get cityName => city?.name.en.isNotEmpty == true
      ? city?.name.en
      : (city?.name.ar.isNotEmpty == true ? city?.name.ar : null);
  String? get countryName => country?.name.en.isNotEmpty == true
      ? country?.name.en
      : (country?.name.ar.isNotEmpty == true ? country?.name.ar : null);
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
      'officeOwnerId': officeOwnerId,
    };
  }
}
