
import 'package:jeeb_app/features/product/list_product/data/models/product_model.dart';

class OfferModel {
  final String id;
  final String? shortDescription;
  final String? longDescription;
  final List<ProductModel> products;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? discountType;
  final num? discountValue;

  OfferModel({
    required this.id,
    this.shortDescription,
    this.longDescription,
    this.products = const [],
    this.startDate,
    this.endDate,
    this.discountType,
    this.discountValue,
  });

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id']?.toString() ?? '',
      shortDescription: json['shortDescription']?.toString(),
      longDescription: json['longDescription']?.toString(),
      products: json['products'] != null
          ? (json['products'] as List)
              .map((e) => ProductModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate'] as String)
          : null,
      endDate: json['endDate'] != null
          ? DateTime.tryParse(json['endDate'] as String)
          : null,
      discountType: json['discountType']?.toString(),
      discountValue: json['discountValue'] != null
          ? (json['discountValue'] is int
              ? (json['discountValue'] as int).toDouble()
              : (json['discountValue'] as num))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'shortDescription': shortDescription,
      'longDescription': longDescription,
      'products': products.map((e) => e.toJson()).toList(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'discountType': discountType,
      'discountValue': discountValue,
    };
  }
}
