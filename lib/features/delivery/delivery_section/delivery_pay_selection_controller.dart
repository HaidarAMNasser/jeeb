import 'package:flutter/foundation.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

/// Batch selection for “add to payment list” on the delivery completed-orders tab.
class DeliveryPaySelectionController {
  final ValueNotifier<bool> batchMode = ValueNotifier<bool>(false);
  final ValueNotifier<Set<String>> selectedOrderIds =
      ValueNotifier<Set<String>>({});

  /// Last snapshot from the completed tab (for fee totals without a parent [ListOrderBloc]).
  final ValueNotifier<List<OrderEntity>> lastCompletedOrders =
      ValueNotifier<List<OrderEntity>>([]);

  /// Increment to ask the completed tab to re-fetch orders (after successful pay proof).
  final ValueNotifier<int> completedTabReloadTick = ValueNotifier<int>(0);

  bool _pendingSelectAllDeliveredOnNextLoad = false;

  bool get pendingSelectAllOnNextLoad =>
      _pendingSelectAllDeliveredOnNextLoad;

  void enterBatchModeWithDeliveredIds(Set<String> ids) {
    batchMode.value = true;
    _pendingSelectAllDeliveredOnNextLoad = false;
    selectedOrderIds.value = Set<String>.from(ids);
  }

  /// Used from order details → user should land on orders tab; list will preselect delivered rows.
  void requestSelectAllDeliveredAfterListLoads() {
    batchMode.value = true;
    _pendingSelectAllDeliveredOnNextLoad = true;
    selectedOrderIds.value = <String>{};
  }

  void onCompletedOrdersLoaded(Iterable<OrderEntity> orders) {
    lastCompletedOrders.value = orders.toList();
    if (!batchMode.value) return;
    if (!_pendingSelectAllDeliveredOnNextLoad) return;
    final deliveredIds = orders
        .where((o) => OrderStatus.fromString(o.status) == OrderStatus.delivered)
        .map((o) => o.id)
        .toSet();
    selectedOrderIds.value = deliveredIds;
    _pendingSelectAllDeliveredOnNextLoad = false;
  }

  void toggleOrderId(String id) {
    final next = Set<String>.from(selectedOrderIds.value);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    selectedOrderIds.value = next;
  }

  void clear() {
    batchMode.value = false;
    selectedOrderIds.value = <String>{};
    _pendingSelectAllDeliveredOnNextLoad = false;
  }

  void dispose() {
    batchMode.dispose();
    selectedOrderIds.dispose();
    lastCompletedOrders.dispose();
    completedTabReloadTick.dispose();
  }
}
