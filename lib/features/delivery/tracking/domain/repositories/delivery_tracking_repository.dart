import 'package:dartz/dartz.dart';
import 'package:jeeb_app/core/common/errors/failure.dart';

/// Driver-side tracking: order `routeHistory` + `speed` via backend (not direct order mutation).
abstract class DeliveryTrackingRepository {
  Future<Either<Failure, Unit>> pushLocationUpdate({
    required int orderId,
    required double lat,
    required double lng,
    required int timestampMs,
    required double speedKmh,
  });
}
