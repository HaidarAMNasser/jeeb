import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/empty_state_widget.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_bloc.dart';
import 'package:jeeb_app/features/client_home/presentation/bloc/client_home_state.dart';
import 'package:jeeb_app/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:jeeb_app/features/product/list_product/presentation/widgets/product_list_item.dart';
import 'package:jeeb_app/features/product/list_product/presentation/widgets/products_shimmer.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';

/// Vertical list of product cards.
class ClientHomeProductsList extends StatelessWidget {
  const ClientHomeProductsList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClientHomeBloc, ClientHomeState>(
      buildWhen: (a, b) =>
          a.isProductsLoading != b.isProductsLoading ||
          a.products != b.products,
      builder: (context, state) {
        if (state.isProductsLoading) {
          return const ProductsShimmer();
        }

        final products = state.products;
        if (products.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: AppHeight.s32),
            child: EmptyStateWidget(message: AppTranslation.noProductsFound),
          );
        }
        return BlocBuilder<FavoritesBloc, FavoritesState>(
          buildWhen: (prev, next) => prev != next,
          builder: (context, favState) {
            final favoriteIds = favState is FavoritesLoaded
                ? favState.favoriteProductIds
                : <String>{};
            final togglingIds = favState is FavoritesLoaded
                ? favState.togglingProductIds
                : <String>{};
            return Column(
              children: [
                for (int i = 0; i < products.length; i++) ...[
                  ProductListItem(
                    product: products[i],
                    isFavorite: favoriteIds.contains(products[i].id),
                    isTogglingFavorite: togglingIds.contains(products[i].id),
                    onToggleFavorite: () => context.read<FavoritesBloc>().add(
                      ToggleFavoriteEvent(products[i].id),
                    ),
                  ),
                  if (i < products.length - 1) SizedBox(height: AppHeight.s12),
                ],
              ],
            );
          },
        );
      },
    );
  }
}
