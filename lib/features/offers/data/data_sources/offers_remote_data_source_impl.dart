import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';
import 'offers_remote_data_source.dart';

class OffersRemoteDataSourceImpl implements OffersRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  OffersRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> getOffers({
    int? page,
    int? limit,
    String? search,
    bool? isActive,
    String? merchantId,
  }) {
    return _appApiServiceClient.getOffers(
      page: page,
      limit: limit,
      search: search,
      isActive: isActive,
      merchantId: merchantId,
    );
  }
}
