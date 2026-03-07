part of 'product_details_bloc.dart';

abstract class ProductDetailsEvent extends Equatable {
  const ProductDetailsEvent();

  @override
  List<Object> get props => [];
}

class GetProductDetailsEvent extends ProductDetailsEvent {
  final String id;

  const GetProductDetailsEvent({required this.id});

  @override
  List<Object> get props => [id];
}

