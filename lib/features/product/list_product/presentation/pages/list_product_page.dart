import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/features/product/list_product/presentation/bloc/list_product_bloc.dart';
import 'package:jeeb_app/features/product/list_product/presentation/widgets/product_list_item.dart';
import 'package:jeeb_app/features/favorites/presentation/bloc/favorites_bloc.dart';

class ListProductPage extends StatefulWidget {
  final String? merchantId;
  const ListProductPage({super.key, this.merchantId});

  @override
  State<ListProductPage> createState() => _ListProductPageState();
}

class _ListProductPageState extends State<ListProductPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Initial load is triggered by route when bloc is created
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = context.read<ListProductBloc>().state;
    // Prevent loading more if already loading
    if (state is ListProductLoadingMore) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      if (state is ListProductLoaded && state.hasMore) {
        context.read<ListProductBloc>().add(
          GetProductsEvent(loadMore: true, merchantId: state.merchantId),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: CustomAppBar(title: AppTranslation.products),
      body: BlocBuilder<ListProductBloc, ListProductState>(
        builder: (context, state) {
          return BlocStateHandler<ListProductBloc, ListProductState>(
            bloc: context.read<ListProductBloc>(),
            isLoading: (state) => state is ListProductLoading,
            isError: (state) => state is ListProductError,
            getErrorMessage: (state) => (state as ListProductError).message,
            isSuccess: (state) =>
                state is ListProductLoaded || state is ListProductLoadingMore,
            isEmpty: (state) {
              if (state is ListProductLoaded) {
                return state.products.isEmpty;
              }
              if (state is ListProductLoadingMore) {
                return state.products.isEmpty;
              }
              return false;
            },
            emptyMessage: AppTranslation.noProductsFound,
            getRetryCallback: (state) => () {
              context.read<ListProductBloc>().add(
                GetProductsEvent(merchantId: widget.merchantId ?? '0'),
              );
            },
            successBuilder: (context, productState) {
              final products = productState is ListProductLoaded
                  ? productState.products
                  : (productState as ListProductLoadingMore).products;
              final hasMore = productState is ListProductLoaded
                  ? productState.hasMore
                  : false;

              Widget listView;
              try {
                final favBloc = context.read<FavoritesBloc>();
                listView = BlocBuilder<FavoritesBloc, FavoritesState>(
                  bloc: favBloc,
                  buildWhen: (a, b) => a != b,
                  builder: (context, favState) {
                    final favoriteIds = favState is FavoritesLoaded
                        ? favState.favoriteProductIds
                        : <String>{};
                    final togglingIds = favState is FavoritesLoaded
                        ? favState.togglingProductIds
                        : <String>{};
                    final hasFavoritesState = favState is FavoritesLoaded;
                    return ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(AppPadding.p16),
                      itemCount: products.length + (hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == products.length) {
                          return Padding(
                            padding: EdgeInsets.all(AppPadding.p16),
                            child: const CustomCircleIndicator(),
                          );
                        }
                        final product = products[index];
                        final isFavorite = hasFavoritesState
                            ? favoriteIds.contains(product.id)
                            : (product.isFavorite ?? false);
                        return ProductListItem(
                          product: product,
                          isFavorite: isFavorite,
                          isTogglingFavorite: togglingIds.contains(product.id),
                          onToggleFavorite: () => favBloc.add(
                                ToggleFavoriteEvent(product.id),
                              ),
                        );
                      },
                    );
                  },
                );
              } catch (_) {
                listView = ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(AppPadding.p16),
                  itemCount: products.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == products.length) {
                      return Padding(
                        padding: EdgeInsets.all(AppPadding.p16),
                        child: const CustomCircleIndicator(),
                      );
                    }
                    return ProductListItem(product: products[index]);
                  },
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  final args =
                      ModalRoute.of(context)?.settings.arguments
                          as Map<String, dynamic>?;
                  final merchantId = args?['merchantId'] as String?;
                  context.read<ListProductBloc>().add(
                    GetProductsEvent(merchantId: merchantId),
                  );
                },
                child: listView,
              );
            },
          );
        },
      ),
    );
  }
}
