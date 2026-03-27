import 'package:flutter/material.dart';

/// Order status values. Use this instead of raw strings.
enum OrderStatus {
  pending,
  completed,
  cancelled,
  readyForPickup,
  assigned,
  pickedUp,
  delivered,
  unknown;

  /// Parse from API/string value (case-insensitive).
  static OrderStatus fromString(String? value) {
    if (value == null || value.isEmpty) return OrderStatus.unknown;
    switch (value.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'completed':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'ready_for_pickup':
        return OrderStatus.readyForPickup;
      case 'assigned':
        return OrderStatus.assigned;
      case 'picked_up':
        return OrderStatus.pickedUp;
      case 'delivered':
        return OrderStatus.delivered;
      default:
        return OrderStatus.unknown;
    }
  }

  /// Display label for UI.
  String get displayLabel {
    switch (this) {
      case OrderStatus.readyForPickup:
        return 'Ready for Pickup';
      case OrderStatus.pickedUp:
        return 'Picked Up';
      default:
        return name[0].toUpperCase() + name.substring(1);
    }
  }

  /// Color for status chip/badge.
  Color get color {
    switch (this) {
      case OrderStatus.completed:
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.pending:
      case OrderStatus.readyForPickup:
        return Colors.orange;
      case OrderStatus.assigned:
      case OrderStatus.pickedUp:
        return Colors.blue;
      case OrderStatus.unknown:
        return Colors.grey;
    }
  }

  /// True if complete/cancel actions are allowed (e.g. only for pending).
  bool get canCompleteOrCancel =>
      this == OrderStatus.pending || this == OrderStatus.readyForPickup;
}
