import 'package:equatable/equatable.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';

class OfferEntity extends Equatable {
  final String id;
  final String? shortDescription;
  final String? longDescription;
  final List<ProductEntity> products;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? discountType; // 'PERCENTAGE' or 'VALUE'
  final num? discountValue;

  const OfferEntity({
    required this.id,
    this.shortDescription,
    this.longDescription,
    this.products = const [],
    this.startDate,
    this.endDate,
    this.discountType,
    this.discountValue,
  });

  @override
  List<Object?> get props => [
        id,
        shortDescription,
        longDescription,
        products,
        startDate,
        endDate,
        discountType,
        discountValue,
      ];
}
