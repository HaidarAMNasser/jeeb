import 'package:equatable/equatable.dart';

enum DiscountType { PERCENTAGE, FIXED }

class OfferEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final DiscountType discountType;
  final double discountValue;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String merchantId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OfferProductEntity> products;
  final OfferMerchantEntity merchant;

  const OfferEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.discountType,
    required this.discountValue,
    required this.startDate,
    required this.endDate,
    required this.isActive,
    required this.merchantId,
    required this.createdAt,
    required this.updatedAt,
    this.products = const [],
    required this.merchant,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        discountType,
        discountValue,
        startDate,
        endDate,
        isActive,
        merchantId,
        createdAt,
        updatedAt,
        products,
        merchant,
      ];
}

class OfferProductEntity extends Equatable {
  final String id;
  final String name;
  final double price;
  final double? offerPrice;

  const OfferProductEntity({
    required this.id,
    required this.name,
    required this.price,
    this.offerPrice,
  });

  @override
  List<Object?> get props => [id, name, price, offerPrice];
}

class OfferMerchantEntity extends Equatable {
  final String id;
  final String restaurantName;

  const OfferMerchantEntity({
    required this.id,
    required this.restaurantName,
  });

  @override
  List<Object?> get props => [id, restaurantName];
}
