import 'package:dartz/dartz.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';
import 'package:jeeb_app/core/common/utils/error_handler.dart';
import 'package:jeeb_app/core/infrastructure/network/network_info.dart';
import 'package:jeeb_app/features/category/list_category/data/mappers/category_mapper.dart';
import 'package:jeeb_app/features/category/list_category/data/models/category_model.dart';
import 'package:jeeb_app/features/merchant/merchant_details/data/mappers/merchant_mapper.dart';
import 'package:jeeb_app/features/merchant/merchant_details/data/models/merchant_model.dart';
import 'package:jeeb_app/features/offer/list_offer/data/mappers/offer_mapper.dart';
import 'package:jeeb_app/features/offer/list_offer/data/models/offer_model.dart';
import 'package:jeeb_app/features/product/list_product/data/mappers/product_mapper.dart';
import 'package:jeeb_app/features/product/list_product/data/models/product_model.dart';
import 'package:jeeb_app/features/search/data/data_sources/search_remote_data_source.dart';
import 'package:jeeb_app/features/search/domain/entities/paginated_search_results.dart';
import 'package:jeeb_app/features/search/domain/entities/search_result.dart';
import 'package:jeeb_app/features/search/domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;

  SearchRepositoryImpl(this._remoteDataSource, this._networkInfo);

  @override
  Future<Either<Failure, PaginatedSearchResults>> search({
    required String query,
    int? page,
    int? limit,
  }) async {
    if (!await _networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final response = await _remoteDataSource.search(
        query: query,
        page: page,
        limit: limit,
      );

      print(
        'SearchRepositoryImpl: response.results length=${response.results.length}',
      );
      for (final item in response.results) {
        print(
          'SearchRepositoryImpl: raw item type=${item.runtimeType}, value=$item',
        );
      }

      final results = response.results
          .map((m) {
            SearchResult? mapped;
            if (m is MerchantModel) {
              mapped = MerchantSearchResult(m.toDomain());
            } else if (m is ProductModel) {
              mapped = ProductSearchResult(m.toDomain());
            } else if (m is OfferModel) {
              mapped = OfferSearchResult(m.toDomain());
            } else if (m is CategoryModel) {
              mapped = CategorySearchResult(m.toDomain());
            }
            print(
              'SearchRepositoryImpl: mapped ${m.runtimeType} -> ${mapped.runtimeType}',
            );
            return mapped;
          })
          .whereType<SearchResult>()
          .toList();

      print('SearchRepositoryImpl: mapped results length=${results.length}');
      for (final item in results) {
        print('SearchRepositoryImpl: mapped item type=${item.runtimeType}');
      }

      return Right(
        PaginatedSearchResults(
          results: results,
          pagination: response.pagination,
        ),
      );
    } catch (e) {
      return Left(ErrorHandler.handle(e));
    }
  }
}
