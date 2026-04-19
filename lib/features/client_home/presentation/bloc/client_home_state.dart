import 'package:equatable/equatable.dart';
import 'package:jeeb_app/features/category/list_category/domain/entities/category_entity.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';
import 'package:jeeb_app/features/offer/list_offer/domain/entities/offer_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';

class ClientHomeState extends Equatable {
  static const Object _unset = Object();

  /// API `type` query: `RESTAURANT`, `STORE`, or null for all.
  static const String merchantTypeRestaurant = 'RESTAURANT';
  static const String merchantTypeStore = 'STORE';
  final bool isLoading;
  final bool isCategoriesLoading;
  final bool isMerchantsLoading;
  final bool isProductsLoading;
  final bool isOffersLoading;
  final bool isLoadingMore;
  final bool hasReachedMax;
  final String? errorMessage;
  final List<CategoryEntity> categories;
  final List<MerchantEntity> merchants;
  final List<ProductEntity> products;
  final List<OfferEntity>? offers;
  final String? selectedCategoryId;
  final String? searchQuery;
  final double? minPrice;
  final double? maxPrice;
  final int? minRating;
  /// Passed to merchants/products APIs as `type` when non-null.
  final String? merchantTypeFilter;
  final int page;

  const ClientHomeState({
    this.isLoading = false,
    this.isCategoriesLoading = false,
    this.isMerchantsLoading = false,
    this.isProductsLoading = false,
    this.isOffersLoading = false,
    this.isLoadingMore = false,
    this.hasReachedMax = false,
    this.errorMessage,
    this.categories = const [],
    this.merchants = const [],
    this.products = const [],
    this.offers = const [],
    this.selectedCategoryId,
    this.searchQuery,
    this.minPrice,
    this.maxPrice,
    this.minRating,
    this.merchantTypeFilter,
    this.page = 1,
  });

  ClientHomeState copyWith({
    bool? isLoading,
    bool? isCategoriesLoading,
    bool? isMerchantsLoading,
    bool? isProductsLoading,
    bool? isOffersLoading,
    bool? isLoadingMore,
    bool? hasReachedMax,
    String? errorMessage,
    List<CategoryEntity>? categories,
    List<MerchantEntity>? merchants,
    List<ProductEntity>? products,
    List<OfferEntity>? offers,
    Object? selectedCategoryId = _unset,
    Object? searchQuery = _unset,
    Object? minPrice = _unset,
    Object? maxPrice = _unset,
    Object? minRating = _unset,
    Object? merchantTypeFilter = _unset,
    int? page,
  }) {
    return ClientHomeState(
      isLoading: isLoading ?? this.isLoading,
      isCategoriesLoading: isCategoriesLoading ?? this.isCategoriesLoading,
      isMerchantsLoading: isMerchantsLoading ?? this.isMerchantsLoading,
      isProductsLoading: isProductsLoading ?? this.isProductsLoading,
      isOffersLoading: isOffersLoading ?? this.isOffersLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      errorMessage: errorMessage,
      categories: categories ?? this.categories,
      merchants: merchants ?? this.merchants,
      products: products ?? this.products,
      offers: offers ?? this.offers,
      selectedCategoryId: selectedCategoryId == _unset
          ? this.selectedCategoryId
          : selectedCategoryId as String?,
      searchQuery: searchQuery == _unset
          ? this.searchQuery
          : searchQuery as String?,
      minPrice: minPrice == _unset ? this.minPrice : minPrice as double?,
      maxPrice: maxPrice == _unset ? this.maxPrice : maxPrice as double?,
      minRating: minRating == _unset ? this.minRating : minRating as int?,
      merchantTypeFilter: merchantTypeFilter == _unset
          ? this.merchantTypeFilter
          : merchantTypeFilter as String?,
      page: page ?? this.page,
    );
  }

  ClientHomeState clearFilters() {
    return copyWith(
      minPrice: null,
      maxPrice: null,
      minRating: null,
      selectedCategoryId: null,
      merchantTypeFilter: null,
    );
  }

  bool get isSearchActive => searchQuery != null && searchQuery!.isNotEmpty;

  @override
  List<Object?> get props => [
        isLoading,
        isCategoriesLoading,
        isMerchantsLoading,
        isProductsLoading,
        isOffersLoading,
        isLoadingMore,
        hasReachedMax,
        errorMessage,
        categories,
        merchants,
        products,
        offers,
        selectedCategoryId,
        searchQuery,
        minPrice,
        maxPrice,
        minRating,
        merchantTypeFilter,
        page,
      ];
}
