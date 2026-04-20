import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_status.dart';

/// Delivery listing + order-details badge text for mediator payment states only.
String? deliveryPayStatusBadgeLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.delivered:
      return AppTranslation.deliveryPayStatusDeliveredNotPaid;
    case OrderStatus.paid:
      return AppTranslation.deliveryPayStatusPaidPending;
    case OrderStatus.completed:
      return AppTranslation.deliveryPayStatusCompletedPaid;
    default:
      return null;
  }
}
