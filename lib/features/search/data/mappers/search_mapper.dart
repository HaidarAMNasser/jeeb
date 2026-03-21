import 'package:jeeb_app/features/category/list_category/data/mappers/category_mapper.dart';
import 'package:jeeb_app/features/category/list_category/data/models/category_model.dart';
import 'package:jeeb_app/features/merchant/merchant_details/data/mappers/merchant_mapper.dart';
import 'package:jeeb_app/features/merchant/merchant_details/data/models/merchant_model.dart';
import 'package:jeeb_app/features/offer/list_offer/data/mappers/offer_mapper.dart';
import 'package:jeeb_app/features/offer/list_offer/data/models/offer_model.dart';
import 'package:jeeb_app/features/product/list_product/data/mappers/product_mapper.dart';
import 'package:jeeb_app/features/product/list_product/data/models/product_model.dart';
import 'package:jeeb_app/features/search/domain/entities/search_result.dart';

extension SearchResultMapper on dynamic {
  SearchResult? toSearchResult() {
    if (this is MerchantModel) {
      return MerchantSearchResult((this as MerchantModel).toDomain());
    } else if (this is ProductModel) {
      return ProductSearchResult((this as ProductModel).toDomain());
    } else if (this is OfferModel) {
      return OfferSearchResult((this as OfferModel).toDomain());
    } else if (this is CategoryModel) {
      return CategorySearchResult((this as CategoryModel).toDomain());
    }
    return null;
  }
}
