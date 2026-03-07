import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/product/list_product/presentation/bloc/list_product_bloc.dart';
import 'package:jeeb_app/features/product/list_product/presentation/widgets/product_list_item.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_image_entity.dart';

class MerchantProductsSection extends StatefulWidget {
  final String merchantId;
  final ScrollController? scrollController;

  const MerchantProductsSection({
    super.key,
    required this.merchantId,
    this.scrollController,
  });

  @override
  State<MerchantProductsSection> createState() => _MerchantProductsSectionState();
}

class _MerchantProductsSectionState extends State<MerchantProductsSection> {
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    if (widget.scrollController != null) {
      widget.scrollController!.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    if (widget.scrollController != null) {
      widget.scrollController!.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    if (widget.scrollController == null) return;

    if (widget.scrollController!.position.pixels >=
        widget.scrollController!.position.maxScrollExtent * 0.8) {
      final state = context.read<ListProductBloc>().state;
      if (state is ListProductLoaded && state.hasMore) {
        setState(() {
          _isLoadingMore = true;
        });
        context.read<ListProductBloc>().add(
              GetProductsEvent(
                loadMore: true,
                merchantId: widget.merchantId,
              ),
            );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Commented out BlocStateHandler for fake data display
    // return BlocConsumer<ListProductBloc, ListProductState>(
    //   listener: (context, state) {
    //     if (state is ListProductLoaded) {
    //       setState(() {
    //         _isLoadingMore = false;
    //       });
    //     }
    //     if (state is ListProductError) {
    //       setState(() {
    //         _isLoadingMore = false;
    //       });
    //     }
    //   },
    //   builder: (context, state) {
    //     return BlocStateHandler<ListProductBloc, ListProductState>(
    //       bloc: context.read<ListProductBloc>(),
    //       isLoading: (state) => state is ListProductLoading,
    //       isError: (state) => state is ListProductError,
    //       getErrorMessage: (state) => (state as ListProductError).message,
    //       isSuccess: (state) => state is ListProductLoaded || state is ListProductLoadingMore,
    //       isEmpty: (state) {
    //         if (state is ListProductLoaded) {
    //           return state.products.isEmpty;
    //         }
    //         if (state is ListProductLoadingMore) {
    //           return state.products.isEmpty;
    //         }
    //         return false;
    //       },
    //       emptyMessage: AppTranslation.noProductsFound,
    //       getRetryCallback: (state) => () {
    //         context.read<ListProductBloc>().add(
    //               GetProductsEvent(merchantId: widget.merchantId),
    //             );
    //       },
    //       successBuilder: (context, productState) {
    //         final products = productState is ListProductLoaded
    //             ? productState.products
    //             : (productState as ListProductLoadingMore).products;
    //         final hasMore = productState is ListProductLoaded ? productState.hasMore : false;

    //         return Column(
    //           crossAxisAlignment: CrossAxisAlignment.start,
    //           children: [
    //             CustomText(
    //               text: AppTranslation.products,
    //               textStyle: getBoldStyle(
    //                 fontSize: AppFontSize.s20,
    //                 color: ColorManager.titlesColor,
    //               ),
    //             ),
    //             SizedBox(height: AppHeight.s16),
    //             ListView.builder(
    //               controller: widget.scrollController,
    //               shrinkWrap: true,
    //               physics: const NeverScrollableScrollPhysics(),
    //               itemCount: products.length + (hasMore ? 1 : 0),
    //               itemBuilder: (context, index) {
    //                 if (index == products.length) {
    //                   // Loading more indicator
    //                   return Padding(
    //                     padding: EdgeInsets.all(AppPadding.p16),
    //                     child: const CustomCircleIndicator(),
    //                   );
    //                 }

    //                 final product = products[index];
    //                 return ProductListItem(product: product);
    //               },
    //             ),
    //           ],
    //         );
    //       },
    //     );
    //   },
    // );

    // Fake data for UI testing
    final fakeProducts = _generateFakeProducts();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: AppTranslation.products,
          textStyle: getBoldStyle(
            fontSize: AppFontSize.s20,
            color: ColorManager.titlesColor,
          ),
        ),
        SizedBox(height: AppHeight.s16),
        ListView.builder(
          controller: widget.scrollController,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: fakeProducts.length,
          itemBuilder: (context, index) {
            final product = fakeProducts[index];
            return ProductListItem(product: product);
          },
        ),
      ],
    );
  }

  List<ProductEntity> _generateFakeProducts() {
    return [
      ProductEntity(
        id: '1',
        name: 'Chicken Shawarma',
        description: 'Delicious chicken shawarma with garlic sauce',
        price: 15000, // 150.00 in smallest unit
        stockQuantity: 50,
        categoryName: 'Fast Food',
        rating: 4.5,
        images: [
          ProductImageEntity(
            id: 1,
            url: 'https://picsum.photos/seed/product1/300/300',
            isMain: true,
            displayOrder: 0,
          ),
        ],
      ),
      ProductEntity(
        id: '2',
        name: 'Beef Burger',
        description: 'Juicy beef burger with special sauce',
        price: 25000,
        stockQuantity: 30,
        categoryName: 'Burgers',
        rating: 4.8,
        images: [
          ProductImageEntity(
            id: 2,
            url: 'https://picsum.photos/seed/product2/300/300',
            isMain: true,
            displayOrder: 0,
          ),
        ],
      ),
      ProductEntity(
        id: '3',
        name: 'Pizza Margherita',
        description: 'Classic Italian pizza with fresh mozzarella',
        price: 35000,
        stockQuantity: 25,
        categoryName: 'Pizza',
        rating: 4.7,
        images: [
          ProductImageEntity(
            id: 3,
            url: 'https://picsum.photos/seed/product3/300/300',
            isMain: true,
            displayOrder: 0,
          ),
        ],
      ),
      ProductEntity(
        id: '4',
        name: 'Caesar Salad',
        description: 'Fresh romaine lettuce with caesar dressing',
        price: 18000,
        stockQuantity: 40,
        categoryName: 'Salads',
        rating: 4.3,
        images: [
          ProductImageEntity(
            id: 4,
            url: 'https://picsum.photos/seed/product4/300/300',
            isMain: true,
            displayOrder: 0,
          ),
        ],
      ),
      ProductEntity(
        id: '5',
        name: 'Grilled Chicken',
        description: 'Tender grilled chicken breast',
        price: 28000,
        stockQuantity: 35,
        categoryName: 'Main Course',
        rating: 4.6,
        images: [
          ProductImageEntity(
            id: 5,
            url: 'https://picsum.photos/seed/product5/300/300',
            isMain: true,
            displayOrder: 0,
          ),
        ],
      ),
      ProductEntity(
        id: '6',
        name: 'French Fries',
        description: 'Crispy golden french fries',
        price: 8000,
        stockQuantity: 100,
        categoryName: 'Sides',
        rating: 4.4,
        images: [
          ProductImageEntity(
            id: 6,
            url: 'https://picsum.photos/seed/product6/300/300',
            isMain: true,
            displayOrder: 0,
          ),
        ],
      ),
    ];
  }
}

