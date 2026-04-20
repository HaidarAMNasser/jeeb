import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

/// Admin share: [mediatorCommissionRate] percent of [deliveryCostWithCommission] (e.g. 4 → 4%).
double mediatorAdminFeeAmount(OrderEntity order) {
  final rate = order.mediatorCommissionRate ?? 0;
  final base = order.deliveryCostWithCommission ?? 0;
  return base * rate / 100.0;
}

double sumMediatorAdminFees(Iterable<OrderEntity> orders) {
  var s = 0.0;
  for (final o in orders) {
    s += mediatorAdminFeeAmount(o);
  }
  return s;
}
