import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class MerchantDetailsRemoteDataSource {
  Future<Response> getMerchantDetails(String id);
}

class MerchantDetailsRemoteDataSourceImpl
    implements MerchantDetailsRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  MerchantDetailsRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> getMerchantDetails(String id) {
    return _appApiServiceClient.getMerchantDetails(id);
  }
}

