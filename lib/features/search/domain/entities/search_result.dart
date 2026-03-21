import 'package:equatable/equatable.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/offer/list_offer/domain/entities/offer_entity.dart';
import 'package:jeeb_app/features/category/list_category/domain/entities/category_entity.dart';

sealed class SearchResult extends Equatable {
  const SearchResult();

  @override
  List<Object?> get props => [];
}

class MerchantSearchResult extends SearchResult {
  final MerchantEntity merchant;
  const MerchantSearchResult(this.merchant);
  @override
  List<Object?> get props => [merchant];
}

class ProductSearchResult extends SearchResult {
  final ProductEntity product;
  const ProductSearchResult(this.product);
  @override
  List<Object?> get props => [product];
}

class OfferSearchResult extends SearchResult {
  final OfferEntity offer;
  const OfferSearchResult(this.offer);
  @override
  List<Object?> get props => [offer];
}

class CategorySearchResult extends SearchResult {
  final CategoryEntity category;
  const CategorySearchResult(this.category);
  @override
  List<Object?> get props => [category];
}
