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

/// Nested `customer` on order payloads when top-level names are null.
class OrderCustomerEntity extends Equatable {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? address;

  const OrderCustomerEntity({
    required this.id,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.address,
  });

  String get fullName {
    final f = firstName ?? '';
    final l = lastName ?? '';
    return '$f $l'.trim();
  }

  @override
  List<Object?> get props =>
      [id, firstName, lastName, phone, email, address];
}

/// Inner `remainingTime.text` (human label + optional parts).
class OrderRemainingTimeTextEntity extends Equatable {
  final String? text;
  final int? hours;
  final int? minutes;
  final int? seconds;

  const OrderRemainingTimeTextEntity({
    this.text,
    this.hours,
    this.minutes,
    this.seconds,
  });

  @override
  List<Object?> get props => [text, hours, minutes, seconds];
}

class OrderRemainingTimeEntity extends Equatable {
  final OrderRemainingTimeTextEntity? text;

  const OrderRemainingTimeEntity({this.text});

  String? get displayLabel => text?.text;

  @override
  List<Object?> get props => [text];
}

/// Product row on order `items[]` or inside an offer bundle.
class OrderLineProductEntity extends Equatable {
  final String lineId;
  final String? productId;
  final String productName;
  final int quantity;
  final int unitPriceMinor;
  final int? originalUnitPriceMinor;
  final int lineTotalMinor;
  final int? productDiscountValueMinor;

  const OrderLineProductEntity({
    required this.lineId,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPriceMinor,
    this.originalUnitPriceMinor,
    required this.lineTotalMinor,
    this.productDiscountValueMinor,
  });

  bool get hasUnitDiscount =>
      originalUnitPriceMinor != null &&
      originalUnitPriceMinor! > unitPriceMinor;

  @override
  List<Object?> get props => [
        lineId,
        productId,
        productName,
        quantity,
        unitPriceMinor,
        originalUnitPriceMinor,
        lineTotalMinor,
        productDiscountValueMinor,
      ];
}

class OrderOfferBundleEntity extends Equatable {
  final String id;
  final String name;
  final String? description;
  final int? subtotalMinor;
  final int? offerDiscountMinor;
  final int? totalMinor;
  final List<OrderLineProductEntity> lines;

  const OrderOfferBundleEntity({
    required this.id,
    required this.name,
    this.description,
    this.subtotalMinor,
    this.offerDiscountMinor,
    this.totalMinor,
    this.lines = const [],
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        subtotalMinor,
        offerDiscountMinor,
        totalMinor,
        lines,
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
  final double? itemsTotal;
  final double? offersTotal;
  final double? deliveryFee;
  final double? deliveryEarning;
  final int? preparationTime;
  /// From API `mealPreparationTime` only (minutes).
  final int? mealPreparationMinutes;
  /// From API `deliveryTime` (minutes), if present.
  final int? deliveryTimeMinutes;
  final String? merchantPhone;
  final bool? hideMerchantPhone;
  final OrderOwnerEntity? owner;
  final OrderRemainingTimeEntity? remainingTime;
  final OrderCustomerEntity? customer;
  final DateTime? deliveryDeadline;
  /// Customer drop-off when set; otherwise use [latitude]/[longitude] from `deliveryCoordinates`.
  final OrderOwnerLocationEntity? finalLocation;
  final List<OrderLineProductEntity> itemLines;
  final List<OrderOfferBundleEntity> offerBundles;

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
    this.itemsTotal,
    this.offersTotal,
    this.deliveryFee,
    this.deliveryEarning,
    this.preparationTime,
    this.mealPreparationMinutes,
    this.deliveryTimeMinutes,
    this.merchantPhone,
    this.hideMerchantPhone,
    this.owner,
    this.remainingTime,
    this.customer,
    this.deliveryDeadline,
    this.finalLocation,
    this.itemLines = const [],
    this.offerBundles = const [],
  });

  /// Order-level `customerName` if set; otherwise nested `customer` full name.
  String? get displayCustomerName {
    final n = customerName?.trim();
    if (n != null && n.isNotEmpty) return n;
    final c = customer?.fullName;
    if (c != null && c.isNotEmpty) return c;
    return null;
  }

  /// Customer drop-off line: `deliveryCoordinates.address` (and top-level delivery fields
  /// merged in [OrderModel]), then lat/lng from those coordinates, then `customer.address`.
  String? get displayCustomerAddressLine {
    final d = deliveryAddress?.trim();
    if (d != null && d.isNotEmpty) return d;
    final lat = latitude;
    final lng = longitude;
    if (lat != null && lng != null) {
      return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
    }
    final c = customer?.address?.trim();
    if (c != null && c.isNotEmpty) return c;
    return null;
  }

  /// Restaurant (`owner.location`).
  double? get restaurantLatitude => owner?.location?.lat;
  double? get restaurantLongitude => owner?.location?.lng;

  /// Drop-off: `finalLocation` if present, else `deliveryCoordinates` ([latitude]/[longitude]).
  double? get dropoffLatitude => finalLocation?.lat ?? latitude;
  double? get dropoffLongitude => finalLocation?.lng ?? longitude;

  /// Line shown on order details (restaurant name from API).
  String? get displayRestaurantName {
    final r = owner?.restaurantName?.trim();
    if (r != null && r.isNotEmpty) return r;
    final o = owner;
    if (o != null) {
      final n = o.fullName.trim();
      if (n.isNotEmpty) return n;
    }
    return null;
  }

  OrderEntity copyWith({
    String? id,
    List<ProductEntity>? products,
    DeliveryManEntity? deliveryMan,
    DateTime? date,
    double? longitude,
    double? latitude,
    int? numberOfPeople,
    String? status,
    String? merchantId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? pickupAddress,
    String? deliveryAddress,
    String? distance,
    String? customerName,
    String? customerPhone,
    double? totalPrice,
    double? itemsTotal,
    double? offersTotal,
    double? deliveryFee,
    double? deliveryEarning,
    int? preparationTime,
    int? mealPreparationMinutes,
    int? deliveryTimeMinutes,
    String? merchantPhone,
    bool? hideMerchantPhone,
    OrderOwnerEntity? owner,
    OrderRemainingTimeEntity? remainingTime,
    OrderCustomerEntity? customer,
    DateTime? deliveryDeadline,
    OrderOwnerLocationEntity? finalLocation,
    List<OrderLineProductEntity>? itemLines,
    List<OrderOfferBundleEntity>? offerBundles,
  }) {
    return OrderEntity(
      id: id ?? this.id,
      products: products ?? this.products,
      deliveryMan: deliveryMan ?? this.deliveryMan,
      date: date ?? this.date,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      status: status ?? this.status,
      merchantId: merchantId ?? this.merchantId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      distance: distance ?? this.distance,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      totalPrice: totalPrice ?? this.totalPrice,
      itemsTotal: itemsTotal ?? this.itemsTotal,
      offersTotal: offersTotal ?? this.offersTotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      deliveryEarning: deliveryEarning ?? this.deliveryEarning,
      preparationTime: preparationTime ?? this.preparationTime,
      mealPreparationMinutes:
          mealPreparationMinutes ?? this.mealPreparationMinutes,
      deliveryTimeMinutes: deliveryTimeMinutes ?? this.deliveryTimeMinutes,
      merchantPhone: merchantPhone ?? this.merchantPhone,
      hideMerchantPhone: hideMerchantPhone ?? this.hideMerchantPhone,
      owner: owner ?? this.owner,
      remainingTime: remainingTime ?? this.remainingTime,
      customer: customer ?? this.customer,
      deliveryDeadline: deliveryDeadline ?? this.deliveryDeadline,
      finalLocation: finalLocation ?? this.finalLocation,
      itemLines: itemLines ?? this.itemLines,
      offerBundles: offerBundles ?? this.offerBundles,
    );
  }

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
    itemsTotal,
    offersTotal,
    deliveryFee,
    deliveryEarning,
    preparationTime,
    mealPreparationMinutes,
    deliveryTimeMinutes,
    merchantPhone,
    hideMerchantPhone,
    owner,
    remainingTime,
    customer,
    deliveryDeadline,
    finalLocation,
    itemLines,
    offerBundles,
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
