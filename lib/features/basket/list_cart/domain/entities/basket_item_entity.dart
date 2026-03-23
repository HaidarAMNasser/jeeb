import 'package:equatable/equatable.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';

class BasketItemEntity extends Equatable {
  final String id;
  final ProductEntity product;
  final int quantity;
  final int unitPrice;
  final int totalPrice;

  const BasketItemEntity({
    required this.id,
    required this.product,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  @override
  List<Object?> get props => [id, product, quantity, unitPrice, totalPrice];
}
