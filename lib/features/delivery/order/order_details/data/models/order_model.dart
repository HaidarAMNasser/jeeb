import 'package:jeeb_app/features/city/data/models/city_model.dart';
import 'package:jeeb_app/features/country/data/models/country_model.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/data/models/area_model.dart';
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

int? _minutesFromDynamic(dynamic v) {
  final direct = _toInt(v);
  if (direct != null) return direct;
  final s = v?.toString().trim();
  if (s == null || s.isEmpty) return null;

  // Accept HH:MM:SS or MM:SS from APIs that return clock strings.
  final match = RegExp(r'^(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?$').firstMatch(s);
  if (match == null) return null;
  final a = int.tryParse(match.group(1) ?? '');
  final b = int.tryParse(match.group(2) ?? '');
  final c = int.tryParse(match.group(3) ?? '');
  if (a == null || b == null) return null;

  final hasHours = match.group(3) != null;
  final hours = hasHours ? a : 0;
  final minutes = hasHours ? b : a;
  final seconds = hasHours ? (c ?? 0) : b;
  final totalMinutes = hours * 60 + minutes + (seconds > 0 ? 1 : 0);
  return totalMinutes;
}

/// Restaurant / merchant owner on order payloads (`owner` in API).
class OrderOwnerLocationModel {
  final double? lat;
  final double? lng;

  const OrderOwnerLocationModel({this.lat, this.lng});

  factory OrderOwnerLocationModel.fromJson(Map<String, dynamic> json) {
    return OrderOwnerLocationModel(
      lat: _toDouble(json['lat'] ?? json['latitude']),
      lng: _toDouble(json['lng'] ?? json['longitude']),
    );
  }

  Map<String, dynamic> toJson() => {'lat': lat, 'lng': lng};
}

class OrderOwnerModel {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? address;
  final String? restaurantName;
  final OrderOwnerLocationModel? location;

  const OrderOwnerModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.address,
    this.restaurantName,
    this.location,
  });

  factory OrderOwnerModel.fromJson(Map<String, dynamic> json) {
    OrderOwnerLocationModel? loc;
    final locJson = json['location'];
    if (locJson is Map) {
      loc = OrderOwnerLocationModel.fromJson(
        Map<String, dynamic>.from(locJson),
      );
    }

    return OrderOwnerModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
      restaurantName: json['restaurantName']?.toString(),
      location: loc,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'address': address,
      'restaurantName': restaurantName,
      'location': location?.toJson(),
    };
  }

  String get fullName {
    final f = firstName ?? '';
    final l = lastName ?? '';
    return '$f $l'.trim();
  }
}

OrderOwnerModel? _orderOwnerFromJson(dynamic v) {
  if (v is! Map) return null;
  return OrderOwnerModel.fromJson(Map<String, dynamic>.from(v));
}

class OrderCustomerModel {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? address;

  const OrderCustomerModel({
    required this.id,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.address,
  });

  factory OrderCustomerModel.fromJson(Map<String, dynamic> json) {
    return OrderCustomerModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'email': email,
        'address': address,
      };

  String get fullName {
    final f = firstName ?? '';
    final l = lastName ?? '';
    return '$f $l'.trim();
  }
}

OrderCustomerModel? _orderCustomerFromJson(dynamic v) {
  if (v is! Map) return null;
  return OrderCustomerModel.fromJson(Map<String, dynamic>.from(v));
}

/// `remainingTime.text` from order list/detail (`text`, `hours`, `minutes`, `seconds`).
class OrderRemainingTimeTextModel {
  final String? text;
  final int? hours;
  final int? minutes;
  final int? seconds;

  const OrderRemainingTimeTextModel({
    this.text,
    this.hours,
    this.minutes,
    this.seconds,
  });

  factory OrderRemainingTimeTextModel.fromJson(Map<String, dynamic> json) {
    return OrderRemainingTimeTextModel(
      text: json['text']?.toString(),
      hours: _toInt(json['hours'] ?? json['hour']),
      minutes: _toInt(json['minutes']),
      seconds: _toInt(json['seconds']),
    );
  }

  Map<String, dynamic> toJson() => {
        'text': text,
        'hours': hours,
        'minutes': minutes,
        'seconds': seconds,
      };
}

class OrderRemainingTimeModel {
  final OrderRemainingTimeTextModel? text;

  const OrderRemainingTimeModel({this.text});

  factory OrderRemainingTimeModel.fromJson(Map<String, dynamic> json) {
    OrderRemainingTimeTextModel? inner;
    final t = json['text'];
    // API variants:
    // - Old: { "text": { "text": "...", "minutes": 1, "seconds": 59 } }
    // - New: { "text": "...", "minutes": 0, "seconds": 0 }
    if (t is Map) {
      inner = OrderRemainingTimeTextModel.fromJson(Map<String, dynamic>.from(t));
    } else if (t != null) {
      inner = OrderRemainingTimeTextModel(
        text: t.toString(),
        hours: _toInt(json['hours'] ?? json['hour']),
        minutes: _toInt(json['minutes']),
        seconds: _toInt(json['seconds']),
      );
    } else if (json['minutes'] != null || json['seconds'] != null) {
      inner = OrderRemainingTimeTextModel(
        text: null,
        hours: _toInt(json['hours'] ?? json['hour']),
        minutes: _toInt(json['minutes']),
        seconds: _toInt(json['seconds']),
      );
    }
    return OrderRemainingTimeModel(text: inner);
  }

  Map<String, dynamic> toJson() => {'text': text?.toJson()};
}

OrderRemainingTimeModel? _remainingTimeFromJson(dynamic v) {
  if (v is! Map) return null;
  return OrderRemainingTimeModel.fromJson(Map<String, dynamic>.from(v));
}

List<ProductModel> _productsFromOrderApiJson(Map<String, dynamic> json) {
  final out = <ProductModel>[];

  /// Shown as restaurant name on delivery cards: prefer API `restaurantName`, else owner full name.
  String? ownerMerchantName;
  String? ownerPhone;
  String? ownerId;
  final owner = json['owner'];
  if (owner is Map) {
    final m = Map<String, dynamic>.from(owner);
    final restaurant = m['restaurantName']?.toString().trim();
    if (restaurant != null && restaurant.isNotEmpty) {
      ownerMerchantName = restaurant;
    } else {
      final first = m['firstName']?.toString() ?? '';
      final last = m['lastName']?.toString() ?? '';
      ownerMerchantName =
          '$first $last'.trim().isEmpty ? null : '$first $last'.trim();
    }
    ownerPhone = m['phone']?.toString();
    ownerId = m['id']?.toString();
  } else {
    ownerId = json['ownerId']?.toString() ?? json['merchantId']?.toString();
  }

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
        final lineTotal = m['totalPrice'];
        if (lineTotal is num) {
          pj['finalPrice'] = lineTotal.toInt();
        }
        pj['merchantId'] ??= ownerId;
        pj['merchantName'] ??= ownerMerchantName;
        pj['merchantPhone'] ??= ownerPhone;
        out.add(ProductModel.fromJson(pj));
      } else {
        final name = _localized(m['productName']);
        final unit = m['unitPrice'];
        final lineTotal = m['totalPrice'];
        out.add(
          ProductModel.fromJson({
            'id': m['productId']?.toString() ?? '',
            'name': name.isEmpty ? 'Item ×$qty' : '$name ×$qty',
            'price': unit is num ? unit.toInt() : 0,
            if (lineTotal is num) 'finalPrice': lineTotal.toInt(),
            'merchantId': ownerId,
            'merchantName': ownerMerchantName,
            'merchantPhone': ownerPhone,
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

/// Single product line on an order (`items[]` or offer `products[]`).
class OrderLineProductModel {
  final String lineId;
  final String? productId;
  final String productName;
  final int quantity;
  final int unitPriceMinor;
  final int? originalUnitPriceMinor;
  final int lineTotalMinor;
  final int? productDiscountValueMinor;

  const OrderLineProductModel({
    required this.lineId,
    this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPriceMinor,
    this.originalUnitPriceMinor,
    required this.lineTotalMinor,
    this.productDiscountValueMinor,
  });

  Map<String, dynamic> toJson() => {
        'lineId': lineId,
        'productId': productId,
        'productName': productName,
        'quantity': quantity,
        'unitPriceMinor': unitPriceMinor,
        'originalUnitPriceMinor': originalUnitPriceMinor,
        'lineTotalMinor': lineTotalMinor,
        'productDiscountValueMinor': productDiscountValueMinor,
      };
}

class OrderOfferBundleModel {
  final String id;
  final String name;
  final String? description;
  final int? subtotalMinor;
  final int? offerDiscountMinor;
  final int? totalMinor;
  final List<OrderLineProductModel> lines;

  const OrderOfferBundleModel({
    required this.id,
    required this.name,
    this.description,
    this.subtotalMinor,
    this.offerDiscountMinor,
    this.totalMinor,
    this.lines = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'subtotalMinor': subtotalMinor,
        'offerDiscountMinor': offerDiscountMinor,
        'totalMinor': totalMinor,
        'lines': lines.map((e) => e.toJson()).toList(),
      };
}

OrderLineProductModel _orderLineProductFromItemMap(Map<String, dynamic> m) {
  final qty = _toInt(m['quantity']) ?? 1;
  String name = '';
  Map<String, dynamic>? pj;
  final productJson = m['product'];
  if (productJson is Map) {
    pj = Map<String, dynamic>.from(productJson);
    name = _localized(pj['name']);
  } else {
    name = _localized(m['productName']);
  }
  if (name.isEmpty) name = 'Item';
  final unit = _toInt(m['unitPrice']) ?? 0;
  final orig = _toInt(m['originalUnitPrice']);
  final total = _toInt(m['totalPrice']) ?? 0;
  final disc = _toInt(m['productDiscountValue']) ?? _toInt(m['discount']);
  return OrderLineProductModel(
    lineId: m['id']?.toString() ?? '',
    productId: m['productId']?.toString() ?? pj?['id']?.toString(),
    productName: name,
    quantity: qty,
    unitPriceMinor: unit,
    originalUnitPriceMinor: orig,
    lineTotalMinor: total,
    productDiscountValueMinor: disc,
  );
}

List<OrderLineProductModel> _orderItemLinesFromJson(dynamic items) {
  final out = <OrderLineProductModel>[];
  if (items is! List) return out;
  for (final raw in items) {
    if (raw is! Map) continue;
    out.add(_orderLineProductFromItemMap(Map<String, dynamic>.from(raw)));
  }
  return out;
}

List<OrderOfferBundleModel> _orderOfferBundlesFromJson(dynamic offers) {
  final out = <OrderOfferBundleModel>[];
  if (offers is! List) return out;
  for (final raw in offers) {
    if (raw is! Map) continue;
    final m = Map<String, dynamic>.from(raw);
    final lineList = <OrderLineProductModel>[];
    final prods = m['products'];
    if (prods is List) {
      for (final p in prods) {
        if (p is! Map) continue;
        lineList.add(
          _orderLineProductFromItemMap(Map<String, dynamic>.from(p)),
        );
      }
    }
    out.add(
      OrderOfferBundleModel(
        id: m['id']?.toString() ?? '',
        name: _localized(m['name']),
        description: _localized(m['description']),
        subtotalMinor: _toInt(m['subtotal']),
        offerDiscountMinor: _toInt(m['offerDiscount']),
        totalMinor: _toInt(m['total']),
        lines: lineList,
      ),
    );
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
  final String? merchantPhone;
  final bool? hideMerchantPhone;
  final OrderOwnerModel? owner;
  final OrderRemainingTimeModel? remainingTime;
  final OrderCustomerModel? customer;
  final String? deliveryDeadline;
  final OrderOwnerLocationModel? finalLocation;
  final List<OrderLineProductModel> orderItemLines;
  final List<OrderOfferBundleModel> orderOfferBundles;
  final int? mealPreparationMinutes;
  final int? deliveryTimeMinutes;
  final double? mediatorCommissionRate;
  final double? deliveryCostWithCommission;
  final int? areaId;
  final AreaModel? area;
  final double? subtotal;
  final double? productDiscount;
  final double? offerDiscount;

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
    this.itemsTotal,
    this.offersTotal,
    this.deliveryFee,
    this.deliveryEarning,
    this.preparationTime,
    this.merchantPhone,
    this.hideMerchantPhone,
    this.owner,
    this.remainingTime,
    this.customer,
    this.deliveryDeadline,
    this.finalLocation,
    this.orderItemLines = const [],
    this.orderOfferBundles = const [],
    this.mealPreparationMinutes,
    this.deliveryTimeMinutes,
    this.mediatorCommissionRate,
    this.deliveryCostWithCommission,
    this.areaId,
    this.area,
    this.subtotal,
    this.productDiscount,
    this.offerDiscount,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final lineProducts = _productsFromOrderApiJson(json);
    final ownerModel = _orderOwnerFromJson(json['owner']);
    final remainingTimeModel = _remainingTimeFromJson(json['remainingTime']);
    final customerModel = _orderCustomerFromJson(json['customer']);
    final parsedItemLines = _orderItemLinesFromJson(json['items']);
    final parsedOfferBundles = _orderOfferBundlesFromJson(json['offers']);

    OrderOwnerLocationModel? finalLocationModel;
    final fl = json['finalLocation'];
    if (fl is Map) {
      finalLocationModel = OrderOwnerLocationModel.fromJson(
        Map<String, dynamic>.from(fl),
      );
    }

    double? lat;
    double? lng;
    String? deliveryAddress;
    final dc = json['deliveryCoordinates'];
    if (dc is Map) {
      final m = Map<String, dynamic>.from(dc);
      lat = _toDouble(m['latitude'] ?? m['lat']);
      lng = _toDouble(m['longitude'] ?? m['lng'] ?? m['long']);
      final addr = m['address']?.toString().trim();
      if (addr != null && addr.isNotEmpty) {
        deliveryAddress = addr;
      } else {
        final fa = m['fullAddress']?.toString().trim();
        if (fa != null && fa.isNotEmpty) deliveryAddress = fa;
      }
    }
    lat ??= _toDouble(json['latitude']);
    lng ??= _toDouble(json['longitude']);

    DeliveryManModel? deliveryMan;
    if (json['deliveryMan'] != null) {
      deliveryMan = DeliveryManModel.fromJson(
        Map<String, dynamic>.from(json['deliveryMan'] as Map),
      );
    } else if (json['delivery'] is Map) {
      deliveryMan = DeliveryManModel.fromJson(
        Map<String, dynamic>.from(json['delivery'] as Map),
      );
    } else {
      final da = json['deliveryAssignment'];
      if (da is Map && da['delivery'] != null) {
        deliveryMan = DeliveryManModel.fromJson(
          Map<String, dynamic>.from(da['delivery'] as Map),
        );
      } else {
        final deliveryId = _toInt(json['deliveryId']);
        if (deliveryId != null && deliveryId > 0) {
          deliveryMan = DeliveryManModel(
            id: deliveryId.toString(),
            firstName: '',
            lastName: '',
            email: '',
            phone: '',
          );
        }
      }
    }

    AreaModel? areaModel;
    final areaJson = json['area'];
    if (areaJson is Map) {
      areaModel = AreaModel.fromJson(Map<String, dynamic>.from(areaJson));
    }

    final createdAt = json['createdAt']?.toString();
    final ownerId = json['ownerId'] ??
        json['merchantId'] ??
        (ownerModel != null && ownerModel.id.isNotEmpty ? ownerModel.id : null);

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
      status: json['status']?.toString() ??
          json['orderStatus']?.toString() ??
          json['state']?.toString(),
      merchantId: ownerId?.toString(),
      createdAt: createdAt,
      updatedAt: json['updatedAt']?.toString(),
      pickupAddress: () {
        final oa = ownerModel?.address?.trim();
        if (oa != null && oa.isNotEmpty) return ownerModel!.address;
        return json['pickup_address']?.toString() ?? ownerModel?.address;
      }(),
      deliveryAddress: deliveryAddress ??
          json['delivery_address']?.toString() ??
          json['deliveryAddress']?.toString(),
      distance: json['distance']?.toString(),
      // Top-level only; use [customer] for nested fallback in UI.
      customerName:
          json['customerName']?.toString() ?? json['customer_name']?.toString(),
      customerPhone: () {
        final direct = json['phone']?.toString();
        if (direct != null && direct.isNotEmpty) return direct;
        final c = json['customer'];
        if (c is Map) {
          final m = Map<String, dynamic>.from(c);
          final p = m['phone']?.toString();
          if (p != null && p.isNotEmpty) return p;
        }
        return json['customer_phone']?.toString();
      }(),
      totalPrice: () {
        final v = json['totalAmount'] ?? json['total_price'];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '');
      }(),
      itemsTotal: () {
        final v = json['itemsTotal'];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '');
      }(),
      offersTotal: () {
        final v = json['offersTotal'];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '');
      }(),
      deliveryFee: () {
        final v = json['deliveryFee'] ?? json['delivery_fee'];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '');
      }(),
      deliveryEarning: () {
        final v = json['deliveryEarning'] ?? json['delivery_earning'];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '');
      }(),
      mealPreparationMinutes: _minutesFromDynamic(
        json['mealPreparationTime'] ?? json['meal_preparation_time'],
      ),
      deliveryTimeMinutes: _toInt(json['deliveryTime']),
      preparationTime: () {
        final mp = _minutesFromDynamic(
          json['mealPreparationTime'] ?? json['meal_preparation_time'],
        );
        if (mp != null) return mp;
        final dt = _minutesFromDynamic(json['deliveryTime']);
        if (dt != null) return dt;
        final legacy = json['preparation_time'];
        if (legacy != null) {
          return _minutesFromDynamic(legacy);
        }
        return null;
      }(),
      merchantPhone: () {
        final p = ownerModel?.phone;
        if (p != null && p.isNotEmpty) return p;
        return json['merchant_phone']?.toString();
      }(),
      hideMerchantPhone:
          json['hideMerchantPhone'] == true || json['hide_restaurant_number'] == true,
      owner: ownerModel,
      remainingTime: remainingTimeModel,
      customer: customerModel,
      deliveryDeadline: json['deliveryDeadline']?.toString(),
      finalLocation: finalLocationModel,
      orderItemLines: parsedItemLines,
      orderOfferBundles: parsedOfferBundles,
      mediatorCommissionRate: _toDouble(json['mediatorCommissionRate']),
      deliveryCostWithCommission: () {
        final v = json['deliveryCostWithCommission'];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '');
      }(),
      areaId: _toInt(json['areaId']),
      area: areaModel,
      subtotal: () {
        final v = json['subtotal'];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '');
      }(),
      productDiscount: () {
        final v = json['productDiscount'];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '');
      }(),
      offerDiscount: () {
        final v = json['offerDiscount'];
        if (v is num) return v.toDouble();
        return double.tryParse(v?.toString() ?? '');
      }(),
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
      'itemsTotal': itemsTotal,
      'offersTotal': offersTotal,
      'delivery_fee': deliveryFee,
      'delivery_earning': deliveryEarning,
      'preparation_time': preparationTime,
      'owner': owner?.toJson(),
      'remainingTime': remainingTime?.toJson(),
      'customer': customer?.toJson(),
      'deliveryDeadline': deliveryDeadline,
      'finalLocation': finalLocation?.toJson(),
      'mealPreparationMinutes': mealPreparationMinutes,
      'deliveryTimeMinutes': deliveryTimeMinutes,
      'orderItemLines': orderItemLines.map((e) => e.toJson()).toList(),
      'orderOfferBundles': orderOfferBundles.map((e) => e.toJson()).toList(),
      'mediatorCommissionRate': mediatorCommissionRate,
      'deliveryCostWithCommission': deliveryCostWithCommission,
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
