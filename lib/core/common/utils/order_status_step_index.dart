import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

/// Max timeline step index (inclusive) for hero rail + labels.
const int kOrderTimelineStepMax = 8;

/// Delivered, completed, cancelled, or rejected — finished orders (open [Routes.orderDetails]).
/// Any other status should prefer the live tracking screen ([Routes.orderStatus]).
bool orderStatusIsTerminal(OrderStatus status) {
  switch (status) {
    case OrderStatus.delivered:
    case OrderStatus.paid:
    case OrderStatus.completed:
    case OrderStatus.cancelled:
    case OrderStatus.rejected:
      return true;
    default:
      return false;
  }
}

/// Courier is locked in and client may see driver name/phone on the tracking screen
/// ([assigned] → [onTheWay], excluding terminal states).
bool orderStatusShowsDriverContact(OrderStatus status) {
  switch (status) {
    case OrderStatus.assigned:
    case OrderStatus.preparing:
    case OrderStatus.readyForPickup:
    case OrderStatus.pickedUp:
    case OrderStatus.onTheWay:
      return true;
    default:
      return false;
  }
}

/// Maps backend [OrderStatus] to a linear step index for the tracking timeline (0–8).
/// Order: pending → confirmed → searching → assigned → preparing → readyForPickup
/// → pickedUp → onTheWay → delivered.
int orderStatusToTimelineIndex(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 0;
    case OrderStatus.confirmed:
      return 1;
    case OrderStatus.searching:
      return 2;
    case OrderStatus.assigned:
      return 3;
    case OrderStatus.preparing:
      return 4;
    case OrderStatus.readyForPickup:
      return 5;
    case OrderStatus.pickedUp:
      return 6;
    case OrderStatus.onTheWay:
      return 7;
    case OrderStatus.delivered:
    case OrderStatus.paid:
    case OrderStatus.completed:
      return 8;
    case OrderStatus.cancelled:
    case OrderStatus.rejected:
      return -1;
    case OrderStatus.unknown:
      return 0;
  }
}

/// For demo / rail label index → a status whose [OrderStatusTrackingCopy.trackingHint] matches the step.
OrderStatus orderStatusForTimelineStep(int stepIndex) {
  switch (stepIndex.clamp(0, kOrderTimelineStepMax)) {
    case 0:
      return OrderStatus.pending;
    case 1:
      return OrderStatus.confirmed;
    case 2:
      return OrderStatus.searching;
    case 3:
      return OrderStatus.assigned;
    case 4:
      return OrderStatus.preparing;
    case 5:
      return OrderStatus.readyForPickup;
    case 6:
      return OrderStatus.pickedUp;
    case 7:
      return OrderStatus.onTheWay;
    case 8:
    default:
      return OrderStatus.delivered;
  }
}
