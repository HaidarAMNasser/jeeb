import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class ListMerchantRemoteDataSource {
  Future<Response> getMerchants({
    int? page,
    int? limit,
    String? search,
    int? countryId,
    int? cityId,
    bool? isActive,
  });
}

class ListMerchantRemoteDataSourceImpl implements ListMerchantRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  ListMerchantRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> getMerchants({
    int? page,
    int? limit,
    String? search,
    int? countryId,
    int? cityId,
    bool? isActive,
  }) {
    return _appApiServiceClient.getMerchants(
      page: page,
      limit: limit,
      search: search,
      countryId: countryId,
      cityId: cityId,
      isActive: isActive,
    );
  }
}
