import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/category/list_category/data/repositories/list_category_repository.dart';
import 'package:jeeb_app/features/category/list_category/domain/entities/category_entity.dart';
import 'package:jeeb_app/features/merchant/list_merchant/data/repositories/list_merchant_repository.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';
import 'package:jeeb_app/features/product/list_product/data/repositories/list_product_repository.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_image_entity.dart';
import 'package:jeeb_app/features/offers/data/repositories/offers_repository_impl.dart';
import 'package:jeeb_app/features/offers/domain/entities/offer_entity.dart';
import 'package:jeeb_app/features/client_home/presentation/cubit/client_home_state.dart';

/// Set to true to use local fake data so you can see the design without API.
const bool _useLocalData = true;

class ClientHomeCubit extends Cubit<ClientHomeState> {
  final ListCategoryRepository _categoryRepository;
  final ListMerchantRepository _merchantRepository;
  final ListProductRepository _productRepository;
  final OffersRepositoryImpl _offersRepository;

  static const int _merchantsLimit = 6;
  static const int _productsLimit = 20;
  static const int _offersLimit = 10;

  ClientHomeCubit({
    required ListCategoryRepository categoryRepository,
    required ListMerchantRepository merchantRepository,
    required ListProductRepository productRepository,
    required OffersRepositoryImpl offersRepository,
  })  : _categoryRepository = categoryRepository,
        _merchantRepository = merchantRepository,
        _productRepository = productRepository,
        _offersRepository = offersRepository,
        super(const ClientHomeState());

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    if (_useLocalData) {
      await Future.delayed(const Duration(milliseconds: 600));
      emit(ClientHomeState(
        isLoading: false,
        categories: _localCategories,
        merchants: _localMerchants,
        products: _localProducts(state.selectedCategoryId, state.searchQuery),
        offers: _localOffers,
        selectedCategoryId: state.selectedCategoryId,
        searchQuery: state.searchQuery,
      ));
      return;
    }

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
      isActive: true,
    );

    String? errorMsg;
    List<CategoryEntity> categories = [];
    List<MerchantEntity> merchants = [];
    List<ProductEntity> products = [];
    List<OfferEntity> offers = [];

    categoryResult.fold(
      (f) => errorMsg = f.message,
      (r) => categories = r,
    );
    merchantsResult.fold(
      (f) => errorMsg ??= f.message,
      (r) => merchants = r,
    );
    productsResult.fold(
      (f) => errorMsg ??= f.message,
      (r) => products = r,
    );
    offersResult.fold(
      (f) => errorMsg ??= f.message,
      (r) => offers = r.data,
    );

    emit(ClientHomeState(
      isLoading: false,
      errorMessage: errorMsg,
      categories: categories,
      merchants: merchants,
      products: products,
      offers: offers,
      selectedCategoryId: state.selectedCategoryId,
      searchQuery: state.searchQuery,
    ));
  }

  Future<void> selectCategory(String? categoryId) async {
    emit(state.copyWith(selectedCategoryId: categoryId, isLoading: true));

    if (_useLocalData) {
      await Future.delayed(const Duration(milliseconds: 300));
      emit(state.copyWith(
        isLoading: false,
        products: _localProducts(categoryId, state.searchQuery),
      ));
      return;
    }

    final result = await _productRepository.getProducts(
      page: 1,
      limit: _productsLimit,
      categoryId: categoryId,
      search: state.searchQuery?.isEmpty ?? true ? null : state.searchQuery,
    );

    result.fold(
      (_) => emit(state.copyWith(isLoading: false)),
      (products) => emit(state.copyWith(
            isLoading: false,
            products: products,
          )),
    );
  }

  Future<void> searchProducts(String? query) async {
    emit(state.copyWith(searchQuery: query, isLoading: true));

    if (_useLocalData) {
      await Future.delayed(const Duration(milliseconds: 300));
      final filtered = query == null || query.isEmpty
          ? _localProducts(state.selectedCategoryId, null)
          : _localProducts(state.selectedCategoryId, null)
              .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
              .toList();
      emit(state.copyWith(isLoading: false, products: filtered));
      return;
    }

    final result = await _productRepository.getProducts(
      page: 1,
      limit: _productsLimit,
      categoryId: state.selectedCategoryId,
      search: query?.isEmpty ?? true ? null : query,
    );

    result.fold(
      (_) => emit(state.copyWith(isLoading: false)),
      (products) => emit(state.copyWith(
            isLoading: false,
            products: products,
          )),
    );
  }

  Future<void> refresh() => load();

  // ---------- Local fake data for design preview ----------

  static final List<CategoryEntity> _localCategories = [
    const CategoryEntity(id: '1', name: 'Food'),
    const CategoryEntity(id: '2', name: 'Groceries'),
    const CategoryEntity(id: '3', name: 'Pharmacy'),
    const CategoryEntity(id: '4', name: 'Electronics'),
    const CategoryEntity(id: '5', name: 'Restaurants'),
  ];

  static final List<MerchantEntity> _localMerchants = [
    const MerchantEntity(
      id: '1',
      name: 'Al-Rashid Restaurant',
      email: 'contact@alrashid.com',
      cityName: 'Beirut',
      countryName: 'Lebanon',
      image: 'https://picsum.photos/seed/r1/400/300',
    ),
    const MerchantEntity(
      id: '2',
      name: 'Golden Fork Cafe',
      email: 'hello@goldenfork.com',
      cityName: 'Tripoli',
      countryName: 'Lebanon',
      image: 'https://picsum.photos/seed/r2/400/300',
    ),
    const MerchantEntity(
      id: '3',
      name: 'Mediterranean Delight',
      email: 'info@meddelight.com',
      cityName: 'Sidon',
      countryName: 'Lebanon',
      image: 'https://picsum.photos/seed/r3/400/300',
    ),
    const MerchantEntity(
      id: '4',
      name: 'Spice Garden',
      email: 'orders@spicegarden.com',
      cityName: 'Tyre',
      countryName: 'Lebanon',
      image: 'https://picsum.photos/seed/r4/400/300',
    ),
    const MerchantEntity(
      id: '5',
      name: 'Ocean View Seafood',
      email: 'book@oceanview.com',
      cityName: 'Byblos',
      countryName: 'Lebanon',
      image: 'https://picsum.photos/seed/r5/400/300',
    ),
    const MerchantEntity(
      id: '6',
      name: 'Royal Palace Restaurant',
      email: 'info@royalpalace.com',
      cityName: 'Zahle',
      countryName: 'Lebanon',
      image: 'https://picsum.photos/seed/r6/400/300',
    ),
  ];

  static List<ProductEntity> _localProducts(String? categoryId, String? search) {
    final list = <ProductEntity>[
      ProductEntity(
        id: '1',
        name: 'Margherita Pizza',
        description: 'Classic tomato and mozzarella.',
        price: 12900,
        priceAfterDiscount: 11610,
        categoryId: '1',
        categoryName: 'Food',
        discount: 10,
        discountType: 'PERCENTAGE',
        hasStock: true,
        stockQuantity: 50,
        images: [
          ProductImageEntity(
            id: 1,
            url: 'https://picsum.photos/seed/p1/400/400',
            isMain: true,
            displayOrder: 1,
          ),
        ],
        rating: 4.5,
      ),
      ProductEntity(
        id: '2',
        name: 'Chicken Shawarma',
        description: 'Fresh wraps with garlic sauce.',
        price: 8500,
        categoryId: '1',
        categoryName: 'Food',
        hasStock: true,
        stockQuantity: 30,
        images: [
          ProductImageEntity(
            id: 2,
            url: 'https://picsum.photos/seed/p2/400/400',
            isMain: true,
            displayOrder: 1,
          ),
        ],
        rating: 4.8,
      ),
      ProductEntity(
        id: '3',
        name: 'Beef Burger',
        description: 'Angus beef with cheese and fries.',
        price: 15000,
        priceAfterDiscount: 13500,
        categoryId: '1',
        categoryName: 'Food',
        discount: 10,
        discountType: 'PERCENTAGE',
        hasStock: true,
        stockQuantity: 20,
        images: [
          ProductImageEntity(
            id: 3,
            url: 'https://picsum.photos/seed/p3/400/400',
            isMain: true,
            displayOrder: 1,
          ),
        ],
        rating: 4.2,
      ),
      ProductEntity(
        id: '4',
        name: 'Caesar Salad',
        description: 'Crisp romaine, parmesan, croutons.',
        price: 7500,
        categoryId: '1',
        categoryName: 'Food',
        hasStock: true,
        stockQuantity: 40,
        images: [
          ProductImageEntity(
            id: 4,
            url: 'https://picsum.photos/seed/p4/400/400',
            isMain: true,
            displayOrder: 1,
          ),
        ],
        rating: 4.6,
      ),
      ProductEntity(
        id: '5',
        name: 'Grilled Salmon',
        description: 'Atlantic salmon with vegetables.',
        price: 22000,
        categoryId: '1',
        categoryName: 'Food',
        hasStock: true,
        stockQuantity: 15,
        images: [
          ProductImageEntity(
            id: 5,
            url: 'https://picsum.photos/seed/p5/400/400',
            isMain: true,
            displayOrder: 1,
          ),
        ],
        rating: 4.9,
      ),
      ProductEntity(
        id: '6',
        name: 'Fresh Milk 1L',
        description: 'Full fat dairy milk.',
        price: 3500,
        categoryId: '2',
        categoryName: 'Groceries',
        hasStock: true,
        stockQuantity: 100,
        images: [
          ProductImageEntity(
            id: 6,
            url: 'https://picsum.photos/seed/p6/400/400',
            isMain: true,
            displayOrder: 1,
          ),
        ],
        rating: 4.0,
      ),
      ProductEntity(
        id: '7',
        name: 'Whole Wheat Bread',
        description: 'Freshly baked daily.',
        price: 2500,
        categoryId: '2',
        categoryName: 'Groceries',
        hasStock: true,
        stockQuantity: 80,
        images: [
          ProductImageEntity(
            id: 7,
            url: 'https://picsum.photos/seed/p7/400/400',
            isMain: true,
            displayOrder: 1,
          ),
        ],
        rating: 4.3,
      ),
      ProductEntity(
        id: '8',
        name: 'Vitamin C Tablets',
        description: '1000mg, 30 tablets.',
        price: 12000,
        categoryId: '3',
        categoryName: 'Pharmacy',
        hasStock: true,
        stockQuantity: 50,
        images: [
          ProductImageEntity(
            id: 8,
            url: 'https://picsum.photos/seed/p8/400/400',
            isMain: true,
            displayOrder: 1,
          ),
        ],
        rating: 4.7,
      ),
    ];
    if (categoryId != null) {
      final filtered = list.where((p) => p.categoryId == categoryId).toList();
      return filtered.isEmpty ? list : filtered;
    }
    return list;
  }

  static final List<OfferEntity> _localOffers = [
    OfferEntity(
      id: '1',
      name: 'Weekend Pizza Deal',
      description: 'Buy 2 large pizzas, get 1 medium free.',
      discountType: DiscountType.PERCENTAGE,
      discountValue: 33,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      isActive: true,
      merchantId: '1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      merchant: const OfferMerchantEntity(
        id: '1',
        restaurantName: 'Al-Rashid Restaurant',
      ),
    ),
    OfferEntity(
      id: '2',
      name: 'Lunch Combo',
      description: 'Main + drink + dessert at fixed price.',
      discountType: DiscountType.FIXED,
      discountValue: 5000,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 14)),
      isActive: true,
      merchantId: '2',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      merchant: const OfferMerchantEntity(
        id: '2',
        restaurantName: 'Golden Fork Cafe',
      ),
    ),
    OfferEntity(
      id: '3',
      name: 'Seafood Special',
      description: '20% off all seafood dishes.',
      discountType: DiscountType.PERCENTAGE,
      discountValue: 20,
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 5)),
      isActive: true,
      merchantId: '5',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      merchant: const OfferMerchantEntity(
        id: '5',
        restaurantName: 'Ocean View Seafood',
      ),
    ),
  ];
}
