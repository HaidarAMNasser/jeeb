import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/category/list_category/data/repositories/list_category_repository.dart';
import 'package:jeeb_app/features/merchant/list_merchant/data/repositories/list_merchant_repository.dart';
import 'package:jeeb_app/features/offer/list_offer/data/repositories/list_offer_repository.dart';
import 'package:jeeb_app/features/product/list_product/data/repositories/list_product_repository.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_event.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_state.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';
import 'package:jeeb_app/features/offer/list_offer/domain/entities/offer_entity.dart';
import 'package:jeeb_app/features/search/domain/repositories/search_repository.dart';
import 'package:jeeb_app/features/search/domain/entities/search_result.dart';

class ClientHomeBloc extends Bloc<ClientHomeEvent, ClientHomeState> {
  final ListCategoryRepository _categoryRepository;
  final ListMerchantRepository _merchantRepository;
  final ListProductRepository _productRepository;
  final ListOfferRepository _offersRepository;
  final SearchRepository _searchRepository;

  static const int _merchantsLimit = 6;
  static const int _productsLimit = 20;
  static const int _offersLimit = 10;

  ClientHomeBloc({
    required ListCategoryRepository categoryRepository,
    required ListMerchantRepository merchantRepository,
    required ListProductRepository productRepository,
    required ListOfferRepository offersRepository,
    required SearchRepository searchRepository,
  }) : _categoryRepository = categoryRepository,
       _merchantRepository = merchantRepository,
       _productRepository = productRepository,
       _offersRepository = offersRepository,
       _searchRepository = searchRepository,
       super(const ClientHomeState()) {
    on<LoadClientHomeEvent>(_onLoad);
    on<SelectCategoryEvent>(_onSelectCategory);
    on<SearchProductsEvent>(_onSearchProducts);
    on<RefreshClientHomeEvent>(_onRefresh);
    on<ApplyFiltersEvent>(_onApplyFilters);
    on<LoadMoreProductsEvent>(_onLoadMoreProducts);
    on<GlobalSearchEvent>(_onGlobalSearch);
  }

  Future<void> _onLoad(
    LoadClientHomeEvent event,
    Emitter<ClientHomeState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        isCategoriesLoading: true,
        isMerchantsLoading: true,
        isProductsLoading: true,
        isOffersLoading: true,
        errorMessage: null,
        page: 1,
        hasReachedMax: false,
      ),
    );

    // Start all requests in parallel and update state as they finish
    await Future.wait([
      _categoryRepository.getCategories(page: 1, limit: 20).then((result) {
        if (isClosed) return;
        result.fold(
          (f) => emit(
            state.copyWith(isCategoriesLoading: false, errorMessage: f.message),
          ),
          (paginatedCategories) => emit(
            state.copyWith(
              isCategoriesLoading: false,
              categories: paginatedCategories.categories,
            ),
          ),
        );
      }),
      _merchantRepository.getMerchants(page: 1, limit: _merchantsLimit).then((
        result,
      ) {
        if (isClosed) return;
        result.fold(
          (f) => emit(
            state.copyWith(
              isMerchantsLoading: false,
              errorMessage: state.errorMessage ?? f.message,
            ),
          ),
          (merchants) {
            var orderedMerchants = List<MerchantEntity>.from(merchants);
            if (orderedMerchants.isNotEmpty) {
              orderedMerchants.sort((a, b) {
                final aHasImage = a.image != null && a.image!.isNotEmpty;
                final bHasImage = b.image != null && b.image!.isNotEmpty;
                if (aHasImage == bHasImage) return 0;
                return aHasImage ? -1 : 1;
              });
            }
            emit(
              state.copyWith(
                isMerchantsLoading: false,
                merchants: orderedMerchants,
              ),
            );
          },
        );
      }),
      _productRepository
          .getProducts(
            page: 1,
            limit: _productsLimit,
            categoryId: state.selectedCategoryId,
            search: state.searchQuery?.isEmpty ?? true
                ? null
                : state.searchQuery,
            minPrice: state.minPrice,
            maxPrice: state.maxPrice,
            minRating: state.minRating,
          )
          .then((result) {
            if (isClosed) return;
            result.fold(
              (f) => emit(
                state.copyWith(
                  isProductsLoading: false,
                  errorMessage: state.errorMessage ?? f.message,
                ),
              ),
              (paginatedProducts) => emit(
                state.copyWith(
                  isProductsLoading: false,
                  products: paginatedProducts.products,
                  hasReachedMax:
                      !(paginatedProducts.pagination?.hasNextPage ?? false),
                ),
              ),
            );
          }),
      _offersRepository.getOffers(page: 1, limit: _offersLimit).then((result) {
        if (isClosed) return;
        result.fold(
          (f) => emit(
            state.copyWith(
              isOffersLoading: false,
              errorMessage: state.errorMessage ?? f.message,
            ),
          ),
          (offers) {
            var orderedOffers = List<OfferEntity>.from(offers);
            if (orderedOffers.isNotEmpty) {
              orderedOffers.sort((a, b) {
                final aHasImages = a.products.any((p) => p.images.isNotEmpty);
                final bHasImages = b.products.any((p) => p.images.isNotEmpty);
                if (aHasImages == bHasImages) return 0;
                return aHasImages ? -1 : 1;
              });
            }
            emit(state.copyWith(isOffersLoading: false, offers: orderedOffers));
          },
        );
      }),
    ]);

    emit(state.copyWith(isLoading: false));
  }

  Future<void> _onSelectCategory(
    SelectCategoryEvent event,
    Emitter<ClientHomeState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedCategoryId: event.categoryId,
        isProductsLoading: true,
        page: 1,
        hasReachedMax: false,
        minPrice:
            null, // Clear price filters when selecting category from home chips
        maxPrice: null,
        minRating: null,
      ),
    );

    final result = await _productRepository.getProducts(
      page: 1,
      limit: _productsLimit,
      categoryId: event.categoryId,
      search: state.searchQuery?.isEmpty ?? true ? null : state.searchQuery,
      // Pass nulls to API to ensure a clean category search
      minPrice: null,
      maxPrice: null,
      minRating: null,
    );

    result.fold(
      (_) => emit(state.copyWith(isProductsLoading: false)),
      (paginatedProducts) => emit(
        state.copyWith(
          isProductsLoading: false,
          products: paginatedProducts.products,
          hasReachedMax: !(paginatedProducts.pagination?.hasNextPage ?? false),
        ),
      ),
    );
  }

  Future<void> _onSearchProducts(
    SearchProductsEvent event,
    Emitter<ClientHomeState> emit,
  ) async {
    emit(
      state.copyWith(
        searchQuery: event.query,
        isProductsLoading: true,
        page: 1,
        hasReachedMax: false,
      ),
    );

    final result = await _productRepository.getProducts(
      page: 1,
      limit: _productsLimit,
      categoryId: state.selectedCategoryId,
      search: event.query?.isEmpty ?? true ? null : event.query,
      minPrice: state.minPrice,
      maxPrice: state.maxPrice,
      minRating: state.minRating,
    );

    result.fold(
      (_) => emit(state.copyWith(isProductsLoading: false)),
      (paginatedProducts) => emit(
        state.copyWith(
          isProductsLoading: false,
          products: paginatedProducts.products,
          hasReachedMax: !(paginatedProducts.pagination?.hasNextPage ?? false),
        ),
      ),
    );
  }

  Future<void> _onApplyFilters(
    ApplyFiltersEvent event,
    Emitter<ClientHomeState> emit,
  ) async {
    emit(
      state.copyWith(
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
        minRating: event.minRating,
        selectedCategoryId: event.categoryId,
        isProductsLoading: true,
        page: 1,
        hasReachedMax: false,
      ),
    );

    final result = await _productRepository.getProducts(
      page: 1,
      limit: _productsLimit,
      categoryId: event.categoryId,
      search: state.searchQuery?.isEmpty ?? true ? null : state.searchQuery,
      minPrice: event.minPrice,
      maxPrice: event.maxPrice,
      minRating: event.minRating,
    );

    result.fold(
      (f) => emit(
        state.copyWith(isProductsLoading: false, errorMessage: f.message),
      ),
      (paginatedProducts) => emit(
        state.copyWith(
          isProductsLoading: false,
          products: paginatedProducts.products,
          hasReachedMax: !(paginatedProducts.pagination?.hasNextPage ?? false),
        ),
      ),
    );
  }

  Future<void> _onLoadMoreProducts(
    LoadMoreProductsEvent event,
    Emitter<ClientHomeState> emit,
  ) async {
    if (state.isLoadingMore || state.hasReachedMax) return;

    emit(state.copyWith(isLoadingMore: true));

    final nextPage = state.page + 1;
    final result = await _productRepository.getProducts(
      page: nextPage,
      limit: _productsLimit,
      categoryId: state.selectedCategoryId,
      search: state.searchQuery?.isEmpty ?? true ? null : state.searchQuery,
      minPrice: state.minPrice,
      maxPrice: state.maxPrice,
      minRating: state.minRating,
    );

    result.fold(
      (f) =>
          emit(state.copyWith(isLoadingMore: false, errorMessage: f.message)),
      (paginatedProducts) => emit(
        state.copyWith(
          isLoadingMore: false,
          page: nextPage,
          products: [...state.products, ...paginatedProducts.products],
          hasReachedMax: !(paginatedProducts.pagination?.hasNextPage ?? false),
        ),
      ),
    );
  }

  Future<void> _onRefresh(
    RefreshClientHomeEvent event,
    Emitter<ClientHomeState> emit,
  ) async {
    emit(state.clearFilters().copyWith(searchQuery: null));
    add(const LoadClientHomeEvent());
  }

  Future<void> _onGlobalSearch(
    GlobalSearchEvent event,
    Emitter<ClientHomeState> emit,
  ) async {
    if (event.query.isEmpty) {
      add(const RefreshClientHomeEvent());
      return;
    }

    emit(
      state.copyWith(
        searchQuery: event.query,
        isMerchantsLoading: true,
        isProductsLoading: true,
        isOffersLoading: true,
        page: 1,
        hasReachedMax: false,
        // Keep categories intact during search; only clear sections affected by search
        merchants: [],
        products: [],
        offers: [],
      ),
    );

    final result = await _searchRepository.search(query: event.query);

    result.fold(
      (f) {
        if (state.searchQuery != event.query) return;
        print('ClientHomeBloc._onGlobalSearch: failure=${f.message}');
        emit(
          state.copyWith(
            isMerchantsLoading: false,
            isProductsLoading: false,
            isOffersLoading: false,
            errorMessage: f.message,
          ),
        );
      },
      (paginatedResults) {
        if (state.searchQuery != event.query) return;
        print(
          'ClientHomeBloc._onGlobalSearch: paginatedResults.results length=${paginatedResults.results.length}',
        );
        for (final item in paginatedResults.results) {
          print(
            'ClientHomeBloc._onGlobalSearch: result type=${item.runtimeType}, value=$item',
          );
        }

        final merchants = paginatedResults.results
            .whereType<MerchantSearchResult>()
            .map((e) => e.merchant)
            .toList();
        final products = paginatedResults.results
            .whereType<ProductSearchResult>()
            .map((e) => e.product)
            .toList();
        final offers = paginatedResults.results
            .whereType<OfferSearchResult>()
            .map((e) => e.offer)
            .toList();

        emit(
          state.copyWith(
            isMerchantsLoading: false,
            isProductsLoading: false,
            isOffersLoading: false,
            merchants: merchants,
            products: products,
            offers: offers,
            hasReachedMax:
                true, // Search results usually don't support infinite scroll same way products do
          ),
        );
      },
    );
  }
}
