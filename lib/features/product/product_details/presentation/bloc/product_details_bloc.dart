import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';
import 'package:jeeb_app/features/product/product_details/data/repositories/product_details_repository.dart';

part 'product_details_event.dart';
part 'product_details_state.dart';

class ProductDetailsBloc extends Bloc<ProductDetailsEvent, ProductDetailsState> {
  final ProductDetailsRepository _repository;

  ProductDetailsBloc(this._repository) : super(const ProductDetailsInitial()) {
    on<ProductDetailsEvent>((event, emit) async {
      if (event is GetProductDetailsEvent) {
        emit(const ProductDetailsLoading());
        final result = await _repository.getProductDetails(event.id);
        result.fold(
          (failure) => emit(ProductDetailsError(message: failure.message)),
          (product) => emit(ProductDetailsLoaded(product: product)),
        );
      }
    });
  }
}

