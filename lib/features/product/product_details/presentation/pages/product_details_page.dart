import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/widgets.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/product/product_details/presentation/bloc/product_details_bloc.dart';

class ProductDetailsPage extends StatefulWidget {
  final String productId;

  const ProductDetailsPage({super.key, required this.productId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  @override
  void initState() {
    super.initState();
    // Fetch product details when page loads
    context.read<ProductDetailsBloc>().add(
      GetProductDetailsEvent(id: widget.productId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: CustomAppBar(title: AppTranslation.productDetails),
      body: BlocStateHandler<ProductDetailsBloc, ProductDetailsState>(
        bloc: context.read<ProductDetailsBloc>(),
        isLoading: (state) => state is ProductDetailsLoading,
        isError: (state) => state is ProductDetailsError,
        getErrorMessage: (state) => (state as ProductDetailsError).message,
        isSuccess: (state) => state is ProductDetailsLoaded,
        getRetryCallback: (state) => () {
          context.read<ProductDetailsBloc>().add(
            GetProductDetailsEvent(id: widget.productId),
          );
        },
        successBuilder: (context, productState) {
          final loadedState = productState as ProductDetailsLoaded;

          // Display product details - user can manually navigate to edit if needed
          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                if (loadedState.product.images.isNotEmpty)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(
                          loadedState.product.images.first.url,
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                SizedBox(height: 16),

                // Product Name
                Text(
                  loadedState.product.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.defaultWhite,
                  ),
                ),
                SizedBox(height: 8),

                // Category
                if (loadedState.product.categoryName != null)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: ColorManager.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      loadedState.product.categoryName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: ColorManager.defaultWhite,
                      ),
                    ),
                  ),
                SizedBox(height: 16),

                // Price
                Row(
                  children: [
                    Text(
                      '${(loadedState.product.price / 100).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorManager.primary,
                      ),
                    ),
                    if (loadedState.product.priceAfterDiscount != null) ...[
                      SizedBox(width: 8),
                      Text(
                        '${(loadedState.product.priceAfterDiscount! / 100).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16,
                          decoration: TextDecoration.lineThrough,
                          color: ColorManager.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: 16),

                // Description
                if (loadedState.product.description != null) ...[
                  Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.defaultWhite,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    loadedState.product.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: ColorManager.textSecondary,
                    ),
                  ),
                  SizedBox(height: 16),
                ],

                // Stock Info
                Row(
                  children: [
                    Icon(
                      Icons.inventory,
                      color: ColorManager.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Stock: ${loadedState.product.stockQuantity ?? 0}',
                      style: TextStyle(
                        fontSize: 14,
                        color: ColorManager.defaultWhite,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
