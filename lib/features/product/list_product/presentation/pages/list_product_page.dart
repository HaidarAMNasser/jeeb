import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart'
    as di;
import 'package:jeeb_app/core/infrastructure/services/storage_service.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/bloc_state_handler.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_app_bar.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_circle_indicator.dart';
import 'package:jeeb_app/features/auth/login/domain/entities/user_entity.dart';
import 'package:jeeb_app/features/product/list_product/presentation/bloc/list_product_bloc.dart';
import 'package:jeeb_app/features/product/list_product/presentation/widgets/product_list_item.dart';

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
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(AppPadding.p16),
                  itemCount: products.length + (hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == products.length) {
                      // Loading more indicator
                      return Padding(
                        padding: EdgeInsets.all(AppPadding.p16),
                        child: const CustomCircleIndicator(),
                      );
                    }

                    final product = products[index];
                    return ProductListItem(product: product);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FutureBuilder<String?>(
        future: di.sl<StorageService>().getUserRole(),
        builder: (context, snapshot) {
          final isAdmin = snapshot.data?.toLowerCase() == UserRole.admin.name;
          if (isAdmin) return const SizedBox.shrink();
          return FloatingActionButton(
            backgroundColor: ColorManager.primary,
            onPressed: () {
              Navigator.pushNamed(context, Routes.addProduct);
            },
            child: Icon(Icons.add, color: ColorManager.surface),
          );
        },
      ),
    );
  }
}
