import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/widgets.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/main_navigation/presentation/pages/client_navigation.dart';
import 'package:jeeb_app/features/product/product_details/presentation/bloc/product_details_bloc.dart';
import 'package:jeeb_app/features/product/product_details/presentation/widgets/product_details_content.dart';
import 'package:jeeb_app/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:jeeb_app/features/basket/manage_cart/presentation/bloc/manage_cart_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/common/utils/toast_util.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

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
            final isFavorite =
                state is FavoritesLoaded && state.isFavorite(widget.productId);
            final isToggling =
                state is FavoritesLoaded && state.isToggling(widget.productId);
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
    return BlocConsumer<ManageCartBloc, ManageCartState>(
      listener: (context, state) {
        if (state is ManageCartSuccess) {
          ClientNavigationTabs.openBasketTab();
        } else if (state is ManageCartError) {
          customToast(msg: state.message);
        }
      },
      builder: (context, cartState) {
        return ModalProgressHUD(
          inAsyncCall: cartState is ManageCartLoading,
          progressIndicator: const CircularProgressIndicator(
            color: ColorManager.primary,
          ),
          child: Scaffold(
            backgroundColor: ColorManager.background,
            appBar: CustomAppBar(
              title: AppTranslation.productDetails,
              actions: _buildAppBarActions(context),
            ),
            body: BlocStateHandler<ProductDetailsBloc, ProductDetailsState>(
              bloc: context.read<ProductDetailsBloc>(),
              isLoading: (state) => state is ProductDetailsLoading,
              isError: (state) => state is ProductDetailsError,
              getErrorMessage: (state) =>
                  (state as ProductDetailsError).message,
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
            bottomNavigationBar:
                BlocBuilder<ProductDetailsBloc, ProductDetailsState>(
                  builder: (context, state) {
                    if (state is! ProductDetailsLoaded)
                      return const SizedBox.shrink();
                    final product = state.product;
                    return SafeArea(
                      top: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppPadding.p16,
                          0,
                          AppPadding.p16,
                          AppPadding.p16,
                        ),
                        child: SizedBox(
                          height: AppHeight.s56,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorManager.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () {
                              context.read<ManageCartBloc>().add(
                                AddProductToCartEvent(product.id),
                              );
                            },
                            icon: const Icon(Icons.shopping_basket_outlined),
                            label: Text(AppTranslation.addToCart),
                          ),
                        ),
                      ),
                    );
                  },
                ),
          ),
        );
      },
    );
  }
}
