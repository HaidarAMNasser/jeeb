class BasketOfferModel {
  final String id;
  final String offerId;
  final String offerName;
  final String? offerDescription;
  final int quantity;
  final int subtotal;
  final int discount;

  const BasketOfferModel({
    required this.id,
    required this.offerId,
    required this.offerName,
    this.offerDescription,
    required this.quantity,
    required this.subtotal,
    required this.discount,
  });

  factory BasketOfferModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is num ? v.toInt() : 0;
    final offer = (json['offer'] as Map?)?.cast<String, dynamic>() ?? const {};
    return BasketOfferModel(
      id: json['id']?.toString() ?? '',
      offerId: offer['id']?.toString() ?? '',
      offerName: offer['name']?.toString() ?? '',
      offerDescription:
          offer['description']?.toString() ??
          offer['shortDescription']?.toString(),
      quantity: asInt(json['quantity']),
      subtotal: asInt(json['subtotal']),
      discount: asInt(json['discount']),
    );
  }
}
