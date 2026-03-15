import 'package:jeeb_app/features/merchant/merchant_details/data/models/merchant_model.dart';
import 'package:jeeb_app/features/product/list_product/data/models/product_model.dart';

class OfferModel {
  final String id;
  final String? name;
  final String? description;
  final String? shortDescription;
  final String? longDescription;
  final MerchantModel? merchant;
  final List<ProductModel> products;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? discountType;
  final num? discountValue;

  OfferModel({
    required this.id,
    this.name,
    this.description,
    this.shortDescription,
    this.longDescription,
    this.merchant,
    this.products = const [],
    this.startDate,
    this.endDate,
    this.discountType,
    this.discountValue,
  });

  static String? _string(dynamic v) {
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    if (v is Map && v.isEmpty) return null;
    return v.toString();
  }

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    final name = _string(json['name']);
    final description = _string(json['description']);
    final mer = json['merchant'];
    final MerchantModel? merchantModel = (mer is Map<String, dynamic>)
        ? MerchantModel.fromJson(mer)
        : null;

    return OfferModel(
      id: json['id']?.toString() ?? '',
      name: name,
      description: description,
      shortDescription: json['shortDescription']?.toString() ?? name,
      longDescription: json['longDescription']?.toString() ?? description,
      merchant: merchantModel,
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
      'name': name,
      'description': description,
      'shortDescription': shortDescription,
      'longDescription': longDescription,
      'merchant': merchant?.toJson(),
      'products': products.map((e) => e.toJson()).toList(),
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'discountType': discountType,
      'discountValue': discountValue,
    };
  }
}
