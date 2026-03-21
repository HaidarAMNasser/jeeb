import 'package:dartz/dartz.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import '../entities/paginated_search_results.dart';

abstract class SearchRepository {
  Future<Either<Failure, PaginatedSearchResults>> search({
    required String query,
    int? page,
    int? limit,
  });
}
