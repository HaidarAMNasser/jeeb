import 'package:jeeb_app/features/order/order_details/domain/entities/order_status.dart';

/// Maps backend [OrderStatus] to a linear step index for the tracking timeline (0–6).
int orderStatusToTimelineIndex(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 0;
    case OrderStatus.confirmed:
      return 1;
    case OrderStatus.preparing:
      return 2;
    case OrderStatus.readyForPickup:
      return 3;
    case OrderStatus.assigned:
    case OrderStatus.pickedUp:
      return 4;
    case OrderStatus.onTheWay:
      return 5;
    case OrderStatus.delivered:
    case OrderStatus.completed:
      return 6;
    case OrderStatus.cancelled:
    case OrderStatus.rejected:
      return -1;
    case OrderStatus.unknown:
      return 0;
  }
}
