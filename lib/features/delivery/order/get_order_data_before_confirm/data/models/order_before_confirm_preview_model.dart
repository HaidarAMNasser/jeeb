import 'package:jeeb_app/features/delivery/order/get_order_data_before_confirm/domain/entities/order_before_confirm_preview.dart';

class OrderBeforeConfirmPreviewModel {
  static OrderBeforeConfirmPreview fromDataMap(Map<String, dynamic> m) {
    final merchantRaw = m['merchant'];
    final OrderBeforeConfirmMerchant merchant;
    if (merchantRaw is Map) {
      merchant = _merchantFromMap(
        Map<String, dynamic>.from(merchantRaw),
      );
    } else {
      merchant = const OrderBeforeConfirmMerchant(id: 0);
    }

    final productsRaw = m['products'];
    final products = <OrderBeforeConfirmProductLine>[];
    if (productsRaw is List) {
      for (final e in productsRaw) {
        if (e is Map<String, dynamic>) {
          products.add(_productFromMap(e));
        } else if (e is Map) {
          products.add(_productFromMap(Map<String, dynamic>.from(e)));
        }
      }
    }

    final dest = m['destination'];
    double destLat = 0;
    double destLng = 0;
    if (dest is Map) {
      destLat = _asDouble(dest['lat']) ?? 0;
      destLng = _asDouble(dest['lng']) ?? 0;
    }

    return OrderBeforeConfirmPreview(
      deliveryCostWithCommission: _asInt(m['deliveryCostWithCommission']),
      tipPerKilometerMinorUnits: _asInt(m['tipPerKilometer']),
      mediatorCommissionRatePercent:
          _asDouble(m['mediatorCommissionRate']) ?? 0,
      merchant: merchant,
      products: products,
      productsTotalMinorUnits: _asInt(m['productsTotal']),
      distanceMeters: _asInt(m['distance']),
      distanceKm: _asDouble(m['distanceKm']) ?? 0,
      deliveryCostMinorUnits: _asInt(m['deliveryCost']),
      mediatorCommissionMinorUnits: _asInt(m['mediatorCommission']),
      grandTotalMinorUnits: _asInt(m['grandTotal']),
      destinationLatitude: destLat,
      destinationLongitude: destLng,
    );
  }

  static OrderBeforeConfirmMerchant _merchantFromMap(Map<String, dynamic> m) {
    final loc = m['location'];
    double? lat;
    double? lng;
    if (loc is Map) {
      lat = _asDouble(loc['lat']);
      lng = _asDouble(loc['lng']);
    }
    return OrderBeforeConfirmMerchant(
      id: _asInt(m['id']),
      firstName: m['firstName']?.toString(),
      lastName: m['lastName']?.toString(),
      restaurantName: m['restaurantName']?.toString(),
      phone: m['phone']?.toString(),
      latitude: lat,
      longitude: lng,
    );
  }

  static OrderBeforeConfirmProductLine _productFromMap(Map<String, dynamic> m) {
    return OrderBeforeConfirmProductLine(
      id: _asInt(m['id']),
      name: m['name']?.toString() ?? '',
      quantity: _asInt(m['quantity']),
      itemTotalMinorUnits: _asInt(m['itemTotal']),
      finalPriceMinorUnits: _asInt(m['finalPrice']),
    );
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
