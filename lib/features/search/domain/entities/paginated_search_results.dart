import 'package:jeeb_app/core/common/models/pagination_model.dart';
import 'package:jeeb_app/features/search/domain/entities/search_result.dart';

class PaginatedSearchResults {
  final List<SearchResult> results;
  final PaginationModel pagination;

  PaginatedSearchResults({required this.results, required this.pagination});
}
