import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';

/// Maps backend [OrderStatus] strings (e.g. PENDING, DELIVERED).
enum OrderStatus {
  pending,
  confirmed,
  searching,
  preparing,
  readyForPickup,
  assigned,
  pickedUp,
  onTheWay,
  delivered,
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
      case OrderStatus.completed:
        return AppTranslation.orderStatusLabelDelivered;
      case OrderStatus.cancelled:
        return AppTranslation.orderStatusLabelCancelled;
      case OrderStatus.rejected:
        return AppTranslation.orderStatusLabelRejected;
      case OrderStatus.unknown:
        return AppTranslation.orderStatusLabelUnknown;
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.completed:
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return Colors.red;
      case OrderStatus.pending:
      case OrderStatus.readyForPickup:
        return Colors.orange;
      case OrderStatus.searching:
      case OrderStatus.preparing:
      case OrderStatus.confirmed:
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return ColorManager.defaultBlue;
      case OrderStatus.unknown:
        return Colors.grey;
    }
  }

  /// True if complete/cancel actions are allowed (e.g. only for pending).
  bool get canCompleteOrCancel =>
      this == OrderStatus.pending || this == OrderStatus.readyForPickup;
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
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
      case OrderStatus.rejected:
        return Icons.block_rounded;
      case OrderStatus.unknown:
        return Icons.help_outline_rounded;
    }
  }
}
