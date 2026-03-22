import 'package:jeeb_app/core/common/models/pagination_model.dart';
import 'package:jeeb_app/features/product/list_product/domain/entities/product_entity.dart';

class PaginatedProducts {
  final List<ProductEntity> products;
  final PaginationModel? pagination;

  PaginatedProducts({
    required this.products,
    this.pagination,
  });
}
