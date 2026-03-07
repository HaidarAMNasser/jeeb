import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_image_entity.dart';
import 'package:jeeb_app/features/product/product_details/data/repositories/product_details_repository.dart';

part 'product_details_event.dart';
part 'product_details_state.dart';

class ProductDetailsBloc extends Bloc<ProductDetailsEvent, ProductDetailsState> {
  // ignore: unused_field
  final ProductDetailsRepository _repository; // Will be used when uncommenting API calls

  ProductDetailsBloc(this._repository) : super(const ProductDetailsInitial()) {
    on<ProductDetailsEvent>((event, emit) async {
      if (event is GetProductDetailsEvent) {
        emit(const ProductDetailsLoading());
        
        // FAKE DATA - Commented out real API call
        // final result = await _repository.getProductDetails(event.id);
        // result.fold(
        //   (failure) => emit(ProductDetailsError(message: failure.message)),
        //   (product) => emit(ProductDetailsLoaded(product: product)),
        // );

        // Fake data for product details
        await Future.delayed(const Duration(milliseconds: 800));
        final fakeProduct = _generateFakeProductDetails(event.id);
        emit(ProductDetailsLoaded(product: fakeProduct));
      }
    });
  }

  // Fake data generation for product details
  ProductEntity _generateFakeProductDetails(String productId) {
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

    // Extract index from productId or use a default
    final index = int.tryParse(productId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 1;
    final nameIndex = (index - 1) % productNames.length;
    final categoryIndex = (index - 1) % categories.length;
    final price = 5000 + (index * 500);
    final discount = index % 3 == 0 ? 15 : null;
    final priceAfterDiscount = discount != null
        ? (price * (1 - discount / 100)).round()
        : null;

    return ProductEntity(
      id: productId,
      name: productNames[nameIndex],
      description: 'Delicious ${productNames[nameIndex].toLowerCase()} made with the finest ingredients. This dish features authentic flavors and is prepared fresh daily. Perfect for any occasion, whether you\'re dining in or ordering for delivery.',
      shortDescription: 'Fresh and tasty ${productNames[nameIndex].toLowerCase()}',
      price: price,
      priceAfterDiscount: priceAfterDiscount,
      restaurantId: 'restaurant_${(index % 5) + 1}',
      categoryId: '${(categoryIndex % 5) + 1}', // Match mock categories: 1-5
      categoryName: categories[categoryIndex],
      discount: discount,
      discountType: discount != null ? 'PERCENTAGE' : null,
      hasStock: true,
      stockQuantity: 50 + (index % 100),
      isAvailable: true,
      isExternal: false,
      merchantId: 'merchant_${(index % 3) + 1}',
      images: [
        ProductImageEntity(
          id: index,
          url: 'https://picsum.photos/seed/product${index}/600/600',
          mobileUrl: 'https://picsum.photos/seed/product${index}/400/400',
          thumbnailUrl: 'https://picsum.photos/seed/product${index}/200/200',
          isMain: true,
          displayOrder: 1,
        ),
        ProductImageEntity(
          id: index + 1000,
          url: 'https://picsum.photos/seed/product${index + 1}/600/600',
          mobileUrl: 'https://picsum.photos/seed/product${index + 1}/400/400',
          thumbnailUrl: 'https://picsum.photos/seed/product${index + 1}/200/200',
          isMain: false,
          displayOrder: 2,
        ),
        ProductImageEntity(
          id: index + 2000,
          url: 'https://picsum.photos/seed/product${index + 2}/600/600',
          mobileUrl: 'https://picsum.photos/seed/product${index + 2}/400/400',
          thumbnailUrl: 'https://picsum.photos/seed/product${index + 2}/200/200',
          isMain: false,
          displayOrder: 3,
        ),
      ],
      rating: 4.0 + (index % 10) / 10,
      createdAt: DateTime.now().subtract(Duration(days: index % 30)),
      updatedAt: DateTime.now().subtract(Duration(days: index % 10)),
    );
  }
}