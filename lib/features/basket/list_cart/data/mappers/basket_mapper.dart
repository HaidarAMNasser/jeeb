import 'package:jeeb_app/features/basket/list_cart/data/models/basket_item_model.dart';
import 'package:jeeb_app/features/basket/list_cart/data/models/basket_model.dart';
import 'package:jeeb_app/features/basket/list_cart/data/models/basket_summary_model.dart';
import 'package:jeeb_app/features/basket/list_cart/domain/entities/basket_entity.dart';
import 'package:jeeb_app/features/basket/list_cart/domain/entities/basket_item_entity.dart';
import 'package:jeeb_app/features/basket/list_cart/domain/entities/basket_summary_entity.dart';
import 'package:jeeb_app/features/product/list_product/data/mappers/product_mapper.dart';

extension BasketSummaryMapper on BasketSummaryModel {
  BasketSummaryEntity toDomain() {
    return BasketSummaryEntity(
      itemsSubtotal: itemsSubtotal,
      offersSubtotal: offersSubtotal,
      totalSubtotal: totalSubtotal,
      totalDiscount: totalDiscount,
      finalTotal: finalTotal,
    );
  }
}

extension BasketItemMapper on BasketItemModel {
  BasketItemEntity toDomain() {
    return BasketItemEntity(
      id: id,
      product: product.toDomain(),
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );
  }
}

extension BasketMapper on BasketModel {
  BasketEntity toDomain() {
    return BasketEntity(
      id: id,
      merchantId: merchantId,
      merchantName: merchantName,
      customerPhone: customerPhone,
      items: items.map((e) => e.toDomain()).toList(),
      summary: summary?.toDomain(),
    );
  }
}
