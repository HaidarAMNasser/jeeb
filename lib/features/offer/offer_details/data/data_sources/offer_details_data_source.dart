import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class OfferDetailsRemoteDataSource {
  Future<Response> getOfferDetails(String id);
}

class OfferDetailsRemoteDataSourceImpl
    implements OfferDetailsRemoteDataSource {
  final AppApiServiceClient _client;

  OfferDetailsRemoteDataSourceImpl(this._client);

  @override
  Future<Response> getOfferDetails(String id) {
    return _client.getOfferDetails(id);
  }
}
