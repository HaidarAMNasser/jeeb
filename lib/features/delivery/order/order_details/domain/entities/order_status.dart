import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';

/// Maps backend [OrderStatus] strings (e.g. PENDING, DELIVERED).
/// Declaration order matches the customer tracking timeline (see [orderStatusToTimelineIndex]).
enum OrderStatus {
  pending,
  confirmed,
  searching,
  assigned,
  preparing,
  readyForPickup,
  pickedUp,
  onTheWay,
  delivered,
  paid,
  cancelled,
  rejected,
  completed,
  unknown;

  /// Backend / route map value (inverse of [fromString]).
  String get apiWireValue {
    switch (this) {
      case OrderStatus.pending:
        return 'PENDING';
      case OrderStatus.confirmed:
        return 'CONFIRMED';
      case OrderStatus.searching:
        return 'SEARCHING';
      case OrderStatus.preparing:
        return 'PREPARING';
      case OrderStatus.readyForPickup:
        return 'READY_FOR_PICKUP';
      case OrderStatus.assigned:
        return 'ASSIGNED';
      case OrderStatus.pickedUp:
        return 'PICKED_UP';
      case OrderStatus.onTheWay:
        return 'ON_THE_WAY';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.paid:
        return 'PAID';
      case OrderStatus.cancelled:
        return 'CANCELLED';
      case OrderStatus.rejected:
        return 'REJECTED';
      case OrderStatus.completed:
        return 'COMPLETED';
      case OrderStatus.unknown:
        return 'PENDING';
    }
  }

  static OrderStatus fromString(String? value) {
    if (value == null || value.isEmpty) return OrderStatus.unknown;
    switch (value.toUpperCase()) {
      case 'PENDING':
        return OrderStatus.pending;
      case 'CONFIRMED':
        return OrderStatus.confirmed;
      case 'SEARCHING':
        return OrderStatus.searching;
      case 'PREPARING':
        return OrderStatus.preparing;
      case 'READY_FOR_PICKUP':
        return OrderStatus.readyForPickup;
      case 'ASSIGNED':
        return OrderStatus.assigned;
      case 'PICKED_UP':
        return OrderStatus.pickedUp;
      case 'ON_THE_WAY':
        return OrderStatus.onTheWay;
      case 'DELIVERED':
        return OrderStatus.delivered;
      case 'PAID':
        return OrderStatus.paid;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      case 'REJECTED':
        return OrderStatus.rejected;
      case 'COMPLETED':
        return OrderStatus.completed;
      default:
        return OrderStatus.unknown;
    }
  }

  String get displayLabel {
    switch (this) {
      case OrderStatus.pending:
        return AppTranslation.orderStatusPendingFriendly;
      case OrderStatus.confirmed:
        return AppTranslation.orderStatusLabelConfirmed;
      case OrderStatus.searching:
        return AppTranslation.orderStatusLabelSearching;
      case OrderStatus.preparing:
        return AppTranslation.orderStatusLabelPreparing;
      case OrderStatus.readyForPickup:
        return AppTranslation.orderStatusLabelReadyForPickup;
      case OrderStatus.assigned:
        return AppTranslation.orderStatusLabelAssigned;
      case OrderStatus.pickedUp:
        return AppTranslation.orderStatusLabelPickedUp;
      case OrderStatus.onTheWay:
        return AppTranslation.orderStatusLabelOnTheWay;
      case OrderStatus.delivered:
        return AppTranslation.orderStatusLabelDelivered;
      case OrderStatus.paid:
        return AppTranslation.orderStatusLabelPaid;
      case OrderStatus.completed:
        return AppTranslation.orderStatusLabelCompleted;
      case OrderStatus.cancelled:
        return AppTranslation.orderStatusLabelCancelled;
      case OrderStatus.rejected:
        return AppTranslation.orderStatusLabelRejected;
      case OrderStatus.unknown:
        return AppTranslation.orderStatusLabelUnknown;
    }
  }

  /// Distinct accent per lifecycle stage (badges, timeline dots).
  Color get color {
    switch (this) {
      case OrderStatus.pending:
        return const Color(0xFFFFB74D);
      case OrderStatus.confirmed:
        return const Color(0xFF7986CB);
      case OrderStatus.searching:
        return ColorManager.defaultBlue;
      case OrderStatus.preparing:
        return const Color(0xFF4DB6AC);
      case OrderStatus.readyForPickup:
        return const Color(0xFFFF8A65);
      case OrderStatus.assigned:
        return const Color(0xFF64B5F6);
      case OrderStatus.pickedUp:
        return const Color(0xFF4FC3F7);
      case OrderStatus.onTheWay:
        return const Color(0xFF9575CD);
      case OrderStatus.delivered:
        return const Color(0xFF81C784);
      case OrderStatus.paid:
        return const Color(0xFFFFB300);
      case OrderStatus.completed:
        return const Color(0xFF66BB6A);
      case OrderStatus.cancelled:
        return const Color(0xFFE57373);
      case OrderStatus.rejected:
        return const Color(0xFFEF5350);
      case OrderStatus.unknown:
        return Colors.blueGrey;
    }
  }

  /// True if complete/cancel actions are allowed (e.g. only for pending).
  bool get canCompleteOrCancel =>
      this == OrderStatus.pending || this == OrderStatus.readyForPickup;
}

/// Short explanation under the status badge on the tracking screen.
extension OrderStatusTrackingCopy on OrderStatus {
  /// Friendly line; for [assigned], pass courier name/phone when known.
  String trackingHint({String? deliveryName, String? deliveryPhone}) {
    switch (this) {
      case OrderStatus.pending:
        return AppTranslation.orderTrackHintPending;
      case OrderStatus.confirmed:
        return AppTranslation.orderTrackHintConfirmed;
      case OrderStatus.searching:
        return AppTranslation.orderTrackHintSearching;
      case OrderStatus.assigned:
        final n = deliveryName?.trim() ?? '';
        final p = deliveryPhone?.trim() ?? '';
        if (n.isNotEmpty) {
          return AppTranslation.orderTrackHintAssignedCourier(n, p);
        }
        return AppTranslation.orderTrackHintAssigned;
      case OrderStatus.preparing:
        return AppTranslation.orderTrackHintPreparing;
      case OrderStatus.readyForPickup:
        return AppTranslation.orderTrackHintReadyForPickup;
      case OrderStatus.pickedUp:
        return AppTranslation.orderTrackHintPickedUp;
      case OrderStatus.onTheWay:
        return AppTranslation.orderTrackHintOnTheWay;
      case OrderStatus.delivered:
      case OrderStatus.paid:
      case OrderStatus.completed:
        return AppTranslation.orderTrackHintDelivered;
      case OrderStatus.cancelled:
        return AppTranslation.orderTrackHintCancelled;
      case OrderStatus.rejected:
        return AppTranslation.orderTrackHintRejected;
      case OrderStatus.unknown:
        return AppTranslation.orderTrackHintUnknown;
    }
  }
}

/// Icons for tracking / details UI (timeline, badges).
extension OrderStatusPresentation on OrderStatus {
  IconData get iconData {
    switch (this) {
      case OrderStatus.pending:
        return Icons.schedule_rounded;
      case OrderStatus.confirmed:
        return Icons.verified_outlined;
      case OrderStatus.searching:
        return Icons.search_rounded;
      case OrderStatus.preparing:
        return Icons.restaurant_rounded;
      case OrderStatus.readyForPickup:
        return Icons.takeout_dining_rounded;
      case OrderStatus.assigned:
        return Icons.two_wheeler_rounded;
      case OrderStatus.pickedUp:
        return Icons.inventory_2_outlined;
      case OrderStatus.onTheWay:
        return Icons.delivery_dining_rounded;
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return Icons.home_outlined;
      case OrderStatus.paid:
        return Icons.payments_outlined;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
      case OrderStatus.rejected:
        return Icons.block_rounded;
      case OrderStatus.unknown:
        return Icons.help_outline_rounded;
    }
  }
}
