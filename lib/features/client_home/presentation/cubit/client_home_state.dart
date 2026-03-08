import 'package:equatable/equatable.dart';
import 'package:jeeb_app/features/category/list_category/domain/entities/category_entity.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/offers/domain/entities/offer_entity.dart';

class ClientHomeState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<CategoryEntity> categories;
  final List<MerchantEntity> merchants;
  final List<ProductEntity> products;
  final List<OfferEntity> offers;
  final String? selectedCategoryId;
  final String? searchQuery;

  const ClientHomeState({
    this.isLoading = true,
    this.errorMessage,
    this.categories = const [],
    this.merchants = const [],
    this.products = const [],
    this.offers = const [],
    this.selectedCategoryId,
    this.searchQuery,
  });

  ClientHomeState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<CategoryEntity>? categories,
    List<MerchantEntity>? merchants,
    List<ProductEntity>? products,
    List<OfferEntity>? offers,
    String? selectedCategoryId,
    String? searchQuery,
  }) {
    return ClientHomeState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      categories: categories ?? this.categories,
      merchants: merchants ?? this.merchants,
      products: products ?? this.products,
      offers: offers ?? this.offers,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        categories,
        merchants,
        products,
        offers,
        selectedCategoryId,
        searchQuery,
      ];
}
