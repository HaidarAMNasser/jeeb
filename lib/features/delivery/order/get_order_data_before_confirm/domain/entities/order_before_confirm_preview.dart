import 'package:equatable/equatable.dart';

/// Result of `POST /distance/calculate-delivery-cost` ([Distance_API.md]).
class OrderBeforeConfirmMerchant extends Equatable {
  const OrderBeforeConfirmMerchant({
    required this.id,
    this.firstName,
    this.lastName,
    this.restaurantName,
    this.phone,
    this.latitude,
    this.longitude,
  });

  final int id;
  final String? firstName;
  final String? lastName;
  final String? restaurantName;
  final String? phone;
  final double? latitude;
  final double? longitude;

  String? get displayName {
    final r = restaurantName?.trim();
    if (r != null && r.isNotEmpty) return r;
    final f = firstName ?? '';
    final l = lastName ?? '';
    final n = '$f $l'.trim();
    return n.isEmpty ? null : n;
  }

  @override
  List<Object?> get props =>
      [id, firstName, lastName, restaurantName, phone, latitude, longitude];
}

class OrderBeforeConfirmProductLine extends Equatable {
  const OrderBeforeConfirmProductLine({
    required this.id,
    required this.name,
    required this.quantity,
    required this.itemTotalMinorUnits,
    required this.finalPriceMinorUnits,
  });

  final int id;
  final String name;
  final int quantity;
  final int itemTotalMinorUnits;
  final int finalPriceMinorUnits;

  @override
  List<Object?> get props =>
      [id, name, quantity, itemTotalMinorUnits, finalPriceMinorUnits];
}

class OrderBeforeConfirmPreview extends Equatable {
  const OrderBeforeConfirmPreview({
    required this.tipPerKilometerMinorUnits,
    required this.mediatorCommissionRatePercent,
    required this.deliveryCostWithCommission,
    required this.merchant,
    required this.products,
    required this.productsTotalMinorUnits,
    required this.distanceMeters,
    required this.distanceKm,
    required this.deliveryCostMinorUnits,
    required this.mediatorCommissionMinorUnits,
    required this.grandTotalMinorUnits,
    required this.destinationLatitude,
    required this.destinationLongitude,
  });

  final int tipPerKilometerMinorUnits;
  final double mediatorCommissionRatePercent;
  final OrderBeforeConfirmMerchant merchant;
  final int deliveryCostWithCommission;
  final List<OrderBeforeConfirmProductLine> products;
  final int productsTotalMinorUnits;
  final int distanceMeters;
  final double distanceKm;
  final int deliveryCostMinorUnits;
  final int mediatorCommissionMinorUnits;
  final int grandTotalMinorUnits;
  final double destinationLatitude;
  final double destinationLongitude;

  @override
  List<Object?> get props => [
        tipPerKilometerMinorUnits,
        mediatorCommissionRatePercent,
        merchant,
        products,
        productsTotalMinorUnits,
        distanceMeters,
        distanceKm,
        deliveryCostMinorUnits,
        mediatorCommissionMinorUnits,
        grandTotalMinorUnits,
        destinationLatitude,
        destinationLongitude,
      ];
}
