import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/list_product/data/repositories/list_product_repository.dart';

part 'list_product_event.dart';
part 'list_product_state.dart';

class ListProductBloc extends Bloc<ListProductEvent, ListProductState> {
  final ListProductRepository _repository;
  static const int _pageSize = 20;

  ListProductBloc(this._repository) : super(const ListProductInitial()) {
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
              ),
            );

            final nextPage = currentState.currentPage + 1;
            final result = await _repository.getProducts(
              page: nextPage,
              limit: _pageSize,
              restaurantId: currentState.merchantId,
            );

            result.fold(
              (failure) => emit(ListProductError(message: failure.message)),
              (newProducts) {
                final updatedProducts = [
                  ...currentState.products,
                  ...newProducts,
                ];
                emit(
                  ListProductLoaded(
                    products: updatedProducts,
                    hasMore: newProducts.length == _pageSize,
                    currentPage: nextPage,
                    merchantId: currentState.merchantId,
                  ),
                );
              },
            );
          }
        } else {
          // Initial load or refresh
          emit(const ListProductLoading());
          final result = await _repository.getProducts(
            page: 1,
            limit: _pageSize,
            restaurantId: event.merchantId,
          );

          result.fold(
            (failure) => emit(ListProductError(message: failure.message)),
            (products) => emit(
              ListProductLoaded(
                products: products,
                hasMore: products.length == _pageSize,
                currentPage: 1,
                merchantId: event.merchantId,
              ),
            ),
          );
        }
      }
    });
  }
}
