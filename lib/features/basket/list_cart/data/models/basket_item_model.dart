import 'package:jeeb_app/features/product/list_product/data/models/product_model.dart';

class BasketItemModel {
  final String id;
  final ProductModel product;
  final int quantity;
  final int unitPrice;
  final int totalPrice;

  const BasketItemModel({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  factory BasketItemModel.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) => v is num ? v.toInt() : 0;
    return BasketItemModel(
      id: json['id']?.toString() ?? '',
      product: ProductModel.fromJson(
        (json['product'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      quantity: asInt(json['quantity']),
      unitPrice: asInt(json['unitPrice']),
      totalPrice: asInt(json['totalPrice']),
    );
  }
}
