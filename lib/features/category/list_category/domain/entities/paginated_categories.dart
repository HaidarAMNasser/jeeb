import 'package:jeeb_app/core/common/models/pagination_model.dart';
import 'category_entity.dart';

class PaginatedCategories {
  final List<CategoryEntity> categories;
  final PaginationModel? pagination;

  PaginatedCategories({
    required this.categories,
    this.pagination,
  });
}
