import 'package:jeeb_app/core/infrastructure/api/api_service.dart';

/// REST: `POST /tracking/update-location` → Firebase `routeHistory` + `speed` only.
abstract class DeliveryTrackingRemoteDataSource {
  Future<void> postLocationUpdate({
    required int orderId,
    required double lat,
    required double lng,
    required int timestampMs,
    required double speedKmh,
  });
}

class DeliveryTrackingRemoteDataSourceImpl implements DeliveryTrackingRemoteDataSource {
  DeliveryTrackingRemoteDataSourceImpl(this._client);

  final AppApiServiceClient _client;

  @override
  Future<void> postLocationUpdate({
    required int orderId,
    required double lat,
    required double lng,
    required int timestampMs,
    required double speedKmh,
  }) async {
    await _client.updateDeliveryTrackingLocation(
      orderId,
      lat,
      lng,
      timestampMs,
      speedKmh,
    );
  }
}
