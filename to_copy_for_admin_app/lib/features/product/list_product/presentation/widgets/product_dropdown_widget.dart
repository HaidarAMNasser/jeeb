import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_paginated_dropdown.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/list_product/presentation/bloc/list_product_bloc.dart';

/// Reusable product dropdown using paginated product list (like CountryCityWidget).
class ProductDropdownWidget extends StatefulWidget {
  final void Function(ProductEntity?) onSelectProduct;
  final ProductEntity? selectedProduct;

  const ProductDropdownWidget({
    super.key,
    required this.onSelectProduct,
    this.selectedProduct,
  });

  @override
  State<ProductDropdownWidget> createState() => _ProductDropdownWidgetState();
}

class _ProductDropdownWidgetState extends State<ProductDropdownWidget> {
  @override
  void initState() {
    super.initState();
    context.read<ListProductBloc>().add(const GetProductsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ListProductBloc, ListProductState>(
      builder: (context, state) {
        List<ProductEntity> products = [];
        bool isLoading = false;
        bool isLoadingMore = false;
        bool hasMoreData = true;
        bool isError = false;
        String? errorMessage;

        if (state is ListProductLoading) {
          isLoading = true;
        } else if (state is ListProductError) {
          isError = true;
          errorMessage = state.message;
        } else if (state is ListProductLoaded) {
          products = state.products;
          isLoadingMore = state.isLoadingMore;
          hasMoreData = state.hasMore;
        } else if (state is ListProductLoadingMore) {
          products = state.products;
          isLoadingMore = false;
          hasMoreData = true;
        }

        return CustomPaginatedDropdown<ProductEntity>(
          title: AppTranslation.selectProducts,
          hintText: AppTranslation.selectProducts,
          items: products,
          selectedItem: widget.selectedProduct,
          displayText: (product) => product.name,
          onChanged: widget.onSelectProduct,
          onLoadMore: () {
            if (!isLoadingMore && hasMoreData) {
              context.read<ListProductBloc>().add(
                const GetProductsEvent(loadMore: true),
              );
            }
          },
          isLoading: isLoading,
          isLoadingMore: isLoadingMore,
          hasMoreData: hasMoreData,
          isError: isError,
          errorMessage: errorMessage,
        );
      },
    );
  }
}
