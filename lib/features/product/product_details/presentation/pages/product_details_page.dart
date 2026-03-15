import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/widgets.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/product/product_details/presentation/bloc/product_details_bloc.dart';
import 'package:jeeb_app/features/product/product_details/presentation/widgets/product_details_content.dart';
import 'package:jeeb_app/features/favorites/presentation/bloc/favorites_bloc.dart';

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
    context.read<ProductDetailsBloc>().add(
          GetProductDetailsEvent(id: widget.productId),
        );
  }

  List<Widget>? _buildAppBarActions(BuildContext context) {
    try {
      final favBloc = context.read<FavoritesBloc>();
      return [
        BlocBuilder<FavoritesBloc, FavoritesState>(
          bloc: favBloc,
          buildWhen: (a, b) => a != b,
          builder: (context, state) {
            final isFavorite = state is FavoritesLoaded &&
                state.isFavorite(widget.productId);
            final isToggling = state is FavoritesLoaded &&
                state.isToggling(widget.productId);
            return IconButton(
              icon: isToggling
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.red,
                      ),
                    )
                  : Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: Colors.red,
                    ),
              onPressed: isToggling
                  ? null
                  : () => favBloc.add(ToggleFavoriteEvent(widget.productId)),
            );
          },
        ),
      ];
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: CustomAppBar(
        title: AppTranslation.productDetails,
        actions: _buildAppBarActions(context),
      ),
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
          final product = (productState as ProductDetailsLoaded).product;
          return ProductDetailsContent(product: product);
        },
      ),
    );
  }
}
