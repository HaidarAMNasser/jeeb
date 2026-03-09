import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_image_entity.dart';
import 'package:jeeb_app/features/product/list_product/data/repositories/list_product_repository.dart';
import 'package:jeeb_app/features/merchant/favorites/data/repositories/favorites_repository.dart';
part 'list_product_event.dart';
part 'list_product_state.dart';

class ListProductBloc extends Bloc<ListProductEvent, ListProductState> {
  // ignore: unused_field
  final ListProductRepository _repository;
  final FavoritesRepository _favoritesRepository;
  static const int _pageSize = 20;

  ListProductBloc(this._repository, this._favoritesRepository)
      : super(const ListProductInitial()) {
    on<ListProductEvent>((event, emit) async {
      if (event is GetProductsEvent) {
        if (event.loadMore) {
          // Load more products
          final currentState = state;
          if (currentState is ListProductLoaded) {
            emit(
              ListProductLoadingMore(
                products: currentState.products,
                currentPage: currentState.currentPage,
                favoriteProductIds: currentState.favoriteProductIds,
              ),
            );

            // FAKE DATA - Commented out real API call
            // final nextPage = currentState.currentPage + 1;
            // final result = await _repository.getProducts(
            //   page: nextPage,
            //   limit: _pageSize,
            //   restaurantId: currentState.merchantId,
            // );

            // result.fold(
            //   (failure) => emit(ListProductError(message: failure.message)),
            //   (newProducts) {
            //     final updatedProducts = [
            //       ...currentState.products,
            //       ...newProducts,
            //     ];
            //     emit(ListProductLoaded(
            //       products: updatedProducts,
            //       hasMore: newProducts.length == _pageSize,
            //       currentPage: nextPage,
            //       merchantId: currentState.merchantId,
            //     ));
            //   },
            // );

            // Fake data for load more
            await Future.delayed(const Duration(milliseconds: 500));
            final nextPage = currentState.currentPage + 1;
            final fakeProducts = _generateFakeProducts(
              startIndex: currentState.products.length,
              count: 10,
              merchantId: currentState.merchantId,
            );
            final updatedProducts = [...currentState.products, ...fakeProducts];
            emit(
              ListProductLoaded(
                products: updatedProducts,
                hasMore: fakeProducts.length == _pageSize,
                currentPage: nextPage,
                merchantId: currentState.merchantId,
                favoriteProductIds: currentState.favoriteProductIds,
              ),
            );
          }
        } else {
          // Initial load or refresh
          emit(const ListProductLoading());

          // Fake data for initial load
          await Future.delayed(const Duration(milliseconds: 800));
          final fakeProducts = _generateFakeProducts(
            startIndex: 0,
            count: _pageSize,
            merchantId: event.merchantId,
          );
          emit(
            ListProductLoaded(
              products: fakeProducts,
              hasMore: fakeProducts.length == _pageSize,
              currentPage: 1,
              merchantId: event.merchantId,
            ),
          );
        }
      } else if (event is ToggleFavoriteProductEvent) {
        final currentState = state;
        if (currentState is! ListProductLoaded &&
            currentState is! ListProductLoadingMore) return;
        var productIdInt = int.tryParse(event.productId);
        productIdInt ??= int.tryParse(
            event.productId.replaceFirst(RegExp(r'^product_'), ''));
        if (productIdInt == null) return;
        final result = await _favoritesRepository.toggleFavorites(
          productIds: [productIdInt],
        );
        result.fold(
          (_) => {},
          (favResult) {
            final ids = favResult.productIds;
            if (currentState is ListProductLoaded) {
              emit(currentState.copyWith(favoriteProductIds: ids));
            } else if (currentState is ListProductLoadingMore) {
              emit(ListProductLoadingMore(
                products: currentState.products,
                currentPage: currentState.currentPage,
                favoriteProductIds: ids,
              ));
            }
          },
        );
      }
    });
  }

  // Fake data generation for UI testing
  List<ProductEntity> _generateFakeProducts({
    required int startIndex,
    required int count,
    String? merchantId,
  }) {
    final productNames = [
      'Margherita Pizza',
      'Chicken Shawarma',
      'Beef Burger',
      'Caesar Salad',
      'Grilled Salmon',
      'Pasta Carbonara',
      'Chicken Wings',
      'Vegetable Curry',
      'Fish & Chips',
      'Chicken Tikka',
      'Beef Steak',
      'Vegetable Pizza',
      'Chicken Biryani',
      'Mushroom Risotto',
      'BBQ Ribs',
      'Sushi Platter',
      'Chicken Kebab',
      'Vegetable Soup',
      'Lamb Chops',
      'Seafood Pasta',
      'Chicken Wrap',
      'Beef Tacos',
      'Vegetable Stir Fry',
      'Chicken Curry',
      'Beef Lasagna',
    ];

    final categories = [
      'Pizza',
      'Fast Food',
      'Burgers',
      'Salads',
      'Seafood',
      'Italian',
      'Appetizers',
      'Indian',
      'British',
      'Middle Eastern',
    ];

    return List.generate(count, (index) {
      final globalIndex = startIndex + index;
      final nameIndex = globalIndex % productNames.length;
      final categoryIndex = globalIndex % categories.length;
      final price =
          5000 + (globalIndex * 500); // Prices in smallest currency unit
      final discount = globalIndex % 3 == 0 ? 10 : null;
      final priceAfterDiscount = discount != null
          ? (price * (1 - discount / 100)).round()
          : null;

      return ProductEntity(
        id: 'product_${globalIndex + 1}',
        name: productNames[nameIndex],
        description:
            'Delicious ${productNames[nameIndex].toLowerCase()} made with fresh ingredients and authentic flavors.',
        shortDescription:
            'Fresh and tasty ${productNames[nameIndex].toLowerCase()}',
        price: price,
        priceAfterDiscount: priceAfterDiscount,
        restaurantId: merchantId ?? 'restaurant_${(globalIndex % 5) + 1}',
        categoryId: '${(categoryIndex % 5) + 1}', // Match mock categories: 1-5
        categoryName: categories[categoryIndex],
        discount: discount,
        discountType: discount != null ? 'PERCENTAGE' : null,
        hasStock: true,
        stockQuantity: 50 + (globalIndex % 100),
        isAvailable: true,
        isExternal: false,
        merchantId: merchantId,
        images: [
          ProductImageEntity(
            id: globalIndex + 1,
            url: 'https://picsum.photos/seed/product${globalIndex + 1}/400/400',
            mobileUrl:
                'https://picsum.photos/seed/product${globalIndex + 1}/300/300',
            thumbnailUrl:
                'https://picsum.photos/seed/product${globalIndex + 1}/150/150',
            isMain: true,
            displayOrder: 1,
          ),
        ],
        rating: 4.0 + (globalIndex % 10) / 10,
        createdAt: DateTime.now().subtract(Duration(days: globalIndex % 30)),
        updatedAt: DateTime.now().subtract(Duration(days: globalIndex % 10)),
      );
    });
  }
}
