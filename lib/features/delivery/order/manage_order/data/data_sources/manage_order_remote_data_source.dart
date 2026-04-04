import 'package:dio/dio.dart';
import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

abstract class ManageOrderRemoteDataSource {
  Future<Response> acceptDelivery(String id, int deliveryTime);
  Future<Response> confirmPickup(String id, String reason);
  Future<Response> markOnTheWay(String id, String reason);
  Future<Response> markAsDelivered(
    String id,
    String reason,
    double lat,
    double lng,
  );
  Future<Response> rejectDelivery(String id, String reason);
}

class ManageOrderRemoteDataSourceImpl implements ManageOrderRemoteDataSource {
  final AppApiServiceClient _appApiServiceClient;

  ManageOrderRemoteDataSourceImpl(this._appApiServiceClient);

  @override
  Future<Response> acceptDelivery(String id, int deliveryTime) {
    return _appApiServiceClient.acceptDelivery(id, deliveryTime);
  }

  @override
  Future<Response> confirmPickup(String id, String reason) {
    return _appApiServiceClient.confirmPickup(id, reason);
  }

  @override
  Future<Response> markOnTheWay(String id, String reason) {
    return _appApiServiceClient.markOnTheWay(id, reason);
  }

  @override
  Future<Response> markAsDelivered(
    String id,
    String reason,
    double lat,
    double lng,
  ) {
    return _appApiServiceClient.markAsDelivered(id, reason, lat, lng);
  }

  @override
  Future<Response> rejectDelivery(String id, String reason) {
    return _appApiServiceClient.rejectDelivery(id, reason);
  }
}
