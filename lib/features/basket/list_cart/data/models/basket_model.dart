import 'package:jeeb_app/features/basket/list_cart/data/models/basket_item_model.dart';
import 'package:jeeb_app/features/basket/list_cart/data/models/basket_offer_model.dart';
import 'package:jeeb_app/features/basket/list_cart/data/models/basket_summary_model.dart';

class BasketModel {
  final String id;
  final String? merchantId;
  final String? merchantName;
  final String? customerPhone;
  final List<BasketItemModel> items;
  final List<BasketOfferModel> offers;
  final BasketSummaryModel? summary;

  const BasketModel({
    required this.id,
    this.merchantId,
    this.merchantName,
    this.customerPhone,
    required this.items,
    required this.offers,
    this.summary,
  });

  factory BasketModel.fromJson(Map<String, dynamic> json) {
    final merchant = json['merchant'] as Map<String, dynamic>?;
    final customer = json['customer'] as Map<String, dynamic>?;
    final items = (json['items'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => BasketItemModel.fromJson(e.cast<String, dynamic>()))
        .toList();
    final offers = (json['offers'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => BasketOfferModel.fromJson(e.cast<String, dynamic>()))
        .toList();
    return BasketModel(
      id: json['id']?.toString() ?? '',
      merchantId: merchant?['id']?.toString(),
      merchantName: merchant?['restaurantName']?.toString(),
      customerPhone: customer?['phone']?.toString(),
      items: items,
      offers: offers,
      summary: json['summary'] is Map<String, dynamic>
          ? BasketSummaryModel.fromJson(json['summary'] as Map<String, dynamic>)
          : null,
    );
  }
}
