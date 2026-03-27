import 'package:jeeb_app/features/city/data/models/city_model.dart';
import 'package:jeeb_app/features/country/data/models/country_model.dart';
import 'package:jeeb_app/features/product/list_product/data/models/product_model.dart';

String _localized(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  if (v is Map) {
    final en = v['en'];
    final ar = v['ar'];
    if (en is String && en.isNotEmpty) return en;
    if (ar is String && ar.isNotEmpty) return ar;
    for (final e in v.values) {
      if (e is String && e.isNotEmpty) return e;
    }
  }
  return v.toString();
}

double? _toDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

List<ProductModel> _productsFromOrderApiJson(Map<String, dynamic> json) {
  final out = <ProductModel>[];

  final legacy = json['products'];
  if (legacy is List && legacy.isNotEmpty) {
    for (final item in legacy) {
      if (item is Map<String, dynamic>) {
        out.add(ProductModel.fromJson(item));
      } else if (item is Map) {
        out.add(ProductModel.fromJson(item.cast<String, dynamic>()));
      }
    }
    return out;
  }

  final items = json['items'];
  if (items is List) {
    for (final raw in items) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final qty = _toInt(m['quantity']) ?? 1;
      final productJson = m['product'];
      if (productJson is Map) {
        final pj = Map<String, dynamic>.from(productJson);
        pj['name'] = '${_localized(pj['name'])} ×$qty';
        final unit = m['unitPrice'];
        if (unit is num) {
          pj['price'] = unit.toInt();
        }
        out.add(ProductModel.fromJson(pj));
      } else {
        final name = _localized(m['productName']);
        final unit = m['unitPrice'];
        out.add(
          ProductModel.fromJson({
            'id': m['productId']?.toString() ?? '',
            'name': name.isEmpty ? 'Item ×$qty' : '$name ×$qty',
            'price': unit is num ? unit.toInt() : 0,
            'images': [],
          }),
        );
      }
    }
  }

  final offers = json['offers'];
  if (offers is List) {
    for (final raw in offers) {
      if (raw is! Map) continue;
      final m = Map<String, dynamic>.from(raw);
      final oid = m['id']?.toString() ?? '';
      final title = _localized(m['name']);
      final total = m['total'];
      out.add(
        ProductModel.fromJson({
          'id': 'offer_$oid',
          'name': title.isEmpty ? 'Offer bundle' : title,
          'description': 'Offer',
          'price': total is num ? total.toInt() : 0,
          'images': [],
        }),
      );
    }
  }

  return out;
}

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
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final lineProducts = _productsFromOrderApiJson(json);

    double? lat;
    double? lng;
    final dc = json['deliveryCoordinates'];
    if (dc is Map) {
      final m = Map<String, dynamic>.from(dc);
      lat = _toDouble(m['latitude']);
      lng = _toDouble(m['longitude']);
    }
    lat ??= _toDouble(json['latitude']);
    lng ??= _toDouble(json['longitude']);

    DeliveryManModel? deliveryMan;
    if (json['deliveryMan'] != null) {
      deliveryMan = DeliveryManModel.fromJson(
        Map<String, dynamic>.from(json['deliveryMan'] as Map),
      );
    } else {
      final da = json['deliveryAssignment'];
      if (da is Map && da['delivery'] != null) {
        deliveryMan = DeliveryManModel.fromJson(
          Map<String, dynamic>.from(da['delivery'] as Map),
        );
      }
    }

    final createdAt = json['createdAt']?.toString();
    final ownerId = json['ownerId'] ?? json['merchantId'];

    int? people;
    final items = json['items'];
    if (items is List && items.isNotEmpty) {
      final first = items.first;
      if (first is Map && first['product'] is Map) {
        final p = first['product'] as Map;
        people = _toInt(p['personCount']);
      }
    }

    return OrderModel(
      id: json['id']?.toString() ?? '',
      products: lineProducts.isEmpty ? null : lineProducts,
      deliveryMan: deliveryMan,
      date: createdAt ?? json['date']?.toString(),
      longitude: lng,
      latitude: lat,
      numberOfPeople: people ??
          (json['numberOfPeople'] != null
              ? (json['numberOfPeople'] is int
                    ? json['numberOfPeople'] as int
                    : int.tryParse(json['numberOfPeople'].toString()))
              : null),
      status: json['status']?.toString(),
      merchantId: ownerId?.toString(),
      createdAt: createdAt,
      updatedAt: json['updatedAt']?.toString(),
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
