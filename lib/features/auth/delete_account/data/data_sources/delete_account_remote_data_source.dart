import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class DeleteAccountRemoteDataSource {
  Future<Response> deleteAccount();
}

class DeleteAccountRemoteDataSourceImpl implements DeleteAccountRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  DeleteAccountRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> deleteAccount() {
    return _appApiServiceClient.deleteProfile();
  }
}
