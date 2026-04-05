import 'dart:async';

import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

/// Subscribes to RTDB order status wires for visible searching orders and
/// invokes [onStatusChanged] when a status value actually changes.
class DeliveryOrderStatusWatcher {
  DeliveryOrderStatusWatcher({required this.onStatusChanged});

  final void Function() onStatusChanged;

  final Map<String, StreamSubscription<String?>> _statusSubs = {};
  final Map<String, String?> _lastKnownStatus = {};

  void syncOrders(List<OrderEntity> orders) {
    final activeIds = orders.map((o) => o.id).toSet();

    _statusSubs.keys
        .where((id) => !activeIds.contains(id))
        .toList()
        .forEach((id) {
      _statusSubs.remove(id)?.cancel();
      _lastKnownStatus.remove(id);
    });

    for (final order in orders) {
      if (_statusSubs.containsKey(order.id)) continue;
      _lastKnownStatus[order.id] = order.status;
      _statusSubs[order.id] = di
          .sl<OrderStatusRtdbService>()
          .watchOrderStatusWire(order.id)
          .listen((wire) {
        if (wire == null || wire.trim().isEmpty) return;
        final prev = _lastKnownStatus[order.id];
        final normalizedWire = wire.trim().toUpperCase();
        final normalizedPrev = prev?.trim().toUpperCase();
        if (normalizedWire != normalizedPrev) {
          _lastKnownStatus[order.id] = wire;
          onStatusChanged();
        }
      }, onError: (_) {});
    }
  }

  void clear() {
    for (final sub in _statusSubs.values) {
      sub.cancel();
    }
    _statusSubs.clear();
    _lastKnownStatus.clear();
  }

  void dispose() {
    clear();
  }
}
