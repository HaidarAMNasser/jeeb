import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/category/list_category/data/repositories/list_category_repository.dart';
import 'package:jeeb_app/features/category/list_category/domain/entities/category_entity.dart';
import 'package:jeeb_app/features/merchant/list_merchant/data/repositories/list_merchant_repository.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';
import 'package:jeeb_app/features/offer/list_offer/data/repositories/list_offer_repository.dart';
import 'package:jeeb_app/features/offer/list_offer/domain/entities/offer_entity.dart';
import 'package:jeeb_app/features/product/list_product/data/repositories/list_product_repository.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/client_home/presentation/cubit/client_home_state.dart';

class ClientHomeCubit extends Cubit<ClientHomeState> {
  final ListCategoryRepository _categoryRepository;
  final ListMerchantRepository _merchantRepository;
  final ListProductRepository _productRepository;
  final ListOfferRepository _offersRepository;

  static const int _merchantsLimit = 6;
  static const int _productsLimit = 20;
  static const int _offersLimit = 10;

  ClientHomeCubit({
    required ListCategoryRepository categoryRepository,
    required ListMerchantRepository merchantRepository,
    required ListProductRepository productRepository,
    required ListOfferRepository offersRepository,
  }) : _categoryRepository = categoryRepository,
       _merchantRepository = merchantRepository,
       _productRepository = productRepository,
       _offersRepository = offersRepository,
       super(const ClientHomeState());

  Future<void> load() async {
    if (!isClosed) emit(state.copyWith(isLoading: true, errorMessage: null));

    final categoryResult = await _categoryRepository.getCategories();
    final merchantsResult = await _merchantRepository.getMerchants(
      page: 1,
      limit: _merchantsLimit,
    );
    final productsResult = await _productRepository.getProducts(
      page: 1,
      limit: _productsLimit,
      categoryId: state.selectedCategoryId,
      search: state.searchQuery?.isEmpty ?? true ? null : state.searchQuery,
    );
    final offersResult = await _offersRepository.getOffers(
      page: 1,
      limit: _offersLimit,
    );

    String? errorMsg;
    List<CategoryEntity> categories = [];
    List<MerchantEntity> merchants = [];
    List<ProductEntity> products = [];
    List<OfferEntity>? offers = [];

    categoryResult.fold((f) => errorMsg = f.message, (r) => categories = r);
    merchantsResult.fold((f) => errorMsg ??= f.message, (r) => merchants = r);
    productsResult.fold((f) => errorMsg ??= f.message, (r) => products = r);
    offersResult.fold((f) => errorMsg ??= f.message, (r) => offers = r);

    // Order merchants: those with image first
    if (merchants.isNotEmpty) {
      merchants = List<MerchantEntity>.from(merchants)
        ..sort((a, b) {
          final aHasImage = a.image != null && a.image!.isNotEmpty;
          final bHasImage = b.image != null && b.image!.isNotEmpty;
          if (aHasImage == bHasImage) return 0;
          return aHasImage ? -1 : 1;
        });
    }

    // Order offers: those with product images first
    if (offers != null && offers!.isNotEmpty) {
      offers = List<OfferEntity>.from(offers!)
        ..sort((a, b) {
          final aHasImages =
              a.products.any((p) => p.images.isNotEmpty);
          final bHasImages =
              b.products.any((p) => p.images.isNotEmpty);
          if (aHasImages == bHasImages) return 0;
          return aHasImages ? -1 : 1;
        });
    }

    if (!isClosed) {
      emit(
        ClientHomeState(
          isLoading: false,
          errorMessage: errorMsg,
          categories: categories,
          merchants: merchants,
          products: products,
          offers: offers,
          selectedCategoryId: state.selectedCategoryId,
          searchQuery: state.searchQuery,
        ),
      );
    }
  }

  Future<void> selectCategory(String? categoryId) async {
    if (!isClosed) emit(state.copyWith(selectedCategoryId: categoryId, isLoading: true));

    final result = await _productRepository.getProducts(
      page: 1,
      limit: _productsLimit,
      categoryId: categoryId,
      search: state.searchQuery?.isEmpty ?? true ? null : state.searchQuery,
    );

    if (isClosed) return;
    result.fold(
      (_) => emit(state.copyWith(isLoading: false)),
      (products) => emit(state.copyWith(isLoading: false, products: products)),
    );
  }

  Future<void> searchProducts(String? query) async {
    if (!isClosed) emit(state.copyWith(searchQuery: query, isLoading: true));

    final result = await _productRepository.getProducts(
      page: 1,
      limit: _productsLimit,
      categoryId: state.selectedCategoryId,
      search: query?.isEmpty ?? true ? null : query,
    );

    if (isClosed) return;
    result.fold(
      (_) => emit(state.copyWith(isLoading: false)),
      (products) => emit(state.copyWith(isLoading: false, products: products)),
    );
  }

  Future<void> refresh() => load();
}
