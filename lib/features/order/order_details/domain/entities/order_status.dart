import 'package:flutter/material.dart';

/// Maps backend [OrderStatus] strings (e.g. PENDING, DELIVERED).
enum OrderStatus {
  pending,
  confirmed,
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

  static OrderStatus fromString(String? value) {
    if (value == null || value.isEmpty) return OrderStatus.unknown;
    switch (value.toUpperCase()) {
      case 'PENDING':
        return OrderStatus.pending;
      case 'CONFIRMED':
        return OrderStatus.confirmed;
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
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.readyForPickup:
        return 'Ready for pickup';
      case OrderStatus.assigned:
        return 'Assigned';
      case OrderStatus.pickedUp:
        return 'Picked up';
      case OrderStatus.onTheWay:
        return 'On the way';
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.rejected:
        return 'Rejected';
      case OrderStatus.unknown:
        return 'Unknown';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.delivered:
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
      case OrderStatus.rejected:
        return Colors.red;
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.preparing:
      case OrderStatus.confirmed:
      case OrderStatus.readyForPickup:
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
      case OrderStatus.onTheWay:
        return Colors.blue;
      case OrderStatus.unknown:
        return Colors.grey;
    }
  }

  bool get canCompleteOrCancel => this == OrderStatus.pending;
}
