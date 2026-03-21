import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class ListProductRemoteDataSource {
  Future<Response> getProducts({
    int? page,
    int? limit,
    String? search,
    String? categoryId,
    String? restaurantId,
    double? minPrice,
    double? maxPrice,
    int? minRating,
  });
}

class ListProductRemoteDataSourceImpl implements ListProductRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  ListProductRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> getProducts({
    int? page,
    int? limit,
    String? search,
    String? categoryId,
    String? restaurantId,
    double? minPrice,
    double? maxPrice,
    int? minRating,
  }) {
    return _appApiServiceClient.getProducts(
      page,
      limit,
      search,
      categoryId,
      restaurantId,
      minPrice,
      maxPrice,
      minRating,
    );
  }
}
