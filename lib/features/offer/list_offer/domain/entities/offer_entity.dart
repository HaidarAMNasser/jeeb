import 'package:equatable/equatable.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';

class OfferEntity extends Equatable {
  final String id;
  final String? name;
  final String? description;
  final String? shortDescription;
  final String? longDescription;
  final MerchantEntity? merchant;
  final List<ProductEntity> products;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? discountType; // 'PERCENTAGE' or 'FIXED'
  final num? discountValue;

  const OfferEntity({
    required this.id,
    this.name,
    this.description,
    this.shortDescription,
    this.longDescription,
    this.merchant,
    this.products = const [],
    this.startDate,
    this.endDate,
    this.discountType,
    this.discountValue,
  });

  /// Title for display: name ?? shortDescription ?? longDescription ?? description
  String get displayTitle =>
      name ?? shortDescription ?? longDescription ?? description ?? 'Offer';

  /// Subtitle: description or longDescription
  String? get displayDescription => description ?? longDescription;

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        shortDescription,
        longDescription,
        merchant,
        products,
        startDate,
        endDate,
        discountType,
        discountValue,
      ];
}
