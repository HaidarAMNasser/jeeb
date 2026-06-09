import 'package:equatable/equatable.dart';

/// Domain input for creating an order (API body is built in the data layer).
class CreateOrderParams extends Equatable {
  final int ownerId;
  final List<CreateOrderProductLine> products;
  final List<CreateOrderOfferLine> offers;
  final CreateOrderDeliveryCoordinates delivery;
  final int deliveryFee;
  final String paymentMethod;
  /// Tip in smallest currency unit (see API docs).
  final int tipAmount;
  final int? cityId;
  final int? areaId;
  final String? customerName;
  final String? customerPhone;

  const CreateOrderParams({
    required this.ownerId,
    required this.products,
    required this.offers,
    required this.delivery,
    this.deliveryFee = 0,
    this.paymentMethod = 'CASH',
    this.tipAmount = 0,
    this.cityId,
    this.areaId,
    this.customerName,
    this.customerPhone,
  });

  @override
  List<Object?> get props => [
        ownerId,
        products,
        offers,
        delivery,
        deliveryFee,
        paymentMethod,
        tipAmount,
        cityId,
        areaId,
        customerName,
        customerPhone,
      ];
}

class CreateOrderProductLine extends Equatable {
  final int productId;
  final int quantity;

  const CreateOrderProductLine({required this.productId, required this.quantity});

  @override
  List<Object?> get props => [productId, quantity];
}

class CreateOrderOfferLine extends Equatable {
  final int offerId;
  final int quantity;

  const CreateOrderOfferLine({required this.offerId, required this.quantity});

  @override
  List<Object?> get props => [offerId, quantity];
}

class CreateOrderDeliveryCoordinates extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;
  final String? landmark;
  final String? specialInstructions;

  const CreateOrderDeliveryCoordinates({
    required this.latitude,
    required this.longitude,
    this.address,
    this.landmark,
    this.specialInstructions,
  });

  @override
  List<Object?> get props =>
      [latitude, longitude, address, landmark, specialInstructions];
}
