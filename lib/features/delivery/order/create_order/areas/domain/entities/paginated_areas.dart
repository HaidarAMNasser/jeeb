import 'package:jeeb_app/core/common/models/pagination_model.dart';
import 'package:jeeb_app/features/delivery/order/create_order/areas/domain/entities/area_entity.dart';

class PaginatedAreas {
  final List<AreaEntity> areas;
  final PaginationModel? pagination;

  PaginatedAreas({
    required this.areas,
    this.pagination,
  });
}
