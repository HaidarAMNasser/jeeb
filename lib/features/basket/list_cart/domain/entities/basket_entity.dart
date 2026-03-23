import 'package:equatable/equatable.dart';
import 'package:jeeb_app/features/basket/list_cart/domain/entities/basket_item_entity.dart';
import 'package:jeeb_app/features/basket/list_cart/domain/entities/basket_summary_entity.dart';

class BasketEntity extends Equatable {
  final String id;
  final String? merchantId;
  final String? merchantName;
  final String? customerPhone;
  final List<BasketItemEntity> items;
  final BasketSummaryEntity? summary;

  const BasketEntity({
    required this.id,
    this.merchantId,
    this.merchantName,
    this.customerPhone,
    required this.items,
    this.summary,
  });

  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [
        id,
        merchantId,
        merchantName,
        customerPhone,
        items,
        summary,
      ];
}
