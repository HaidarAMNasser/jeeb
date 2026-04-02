import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

/// Duration for "accept / search" countdown.
///
/// Uses **only** `remainingTime.text.seconds` from the API response.
/// The `minutes` field is unreliable (test data sends total-lifetime minutes).
/// The `text` string is ignored.
/// `deliveryDeadline` is NOT used.
abstract final class OrderRemainingTimeDuration {
  static Duration fromOrder(OrderEntity order) {
    final rt = order.remainingTime?.text;
    if (rt == null) return Duration.zero;

    final s = rt.seconds ?? 0;
    if (s <= 0) return Duration.zero;
    return Duration(seconds: s);
  }
}
