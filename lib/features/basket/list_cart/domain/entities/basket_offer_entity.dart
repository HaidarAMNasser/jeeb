import 'package:equatable/equatable.dart';

class BasketOfferEntity extends Equatable {
  final String id;
  final String offerId;
  final String offerName;
  final String? offerDescription;
  final int quantity;
  final int subtotal;
  final int discount;

  const BasketOfferEntity({
    required this.id,
    required this.offerId,
    required this.offerName,
    this.offerDescription,
    required this.quantity,
    required this.subtotal,
    required this.discount,
  });

  @override
  List<Object?> get props => [
        id,
        offerId,
        offerName,
        offerDescription,
        quantity,
        subtotal,
        discount,
      ];
}
