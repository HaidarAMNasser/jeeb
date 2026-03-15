import 'package:flutter/material.dart';

/// Order status values. Use this instead of raw strings.
enum OrderStatus {
  pending,
  completed,
  cancelled,
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
      default:
        return OrderStatus.unknown;
    }
  }

  /// Display label for UI.
  String get displayLabel => name[0].toUpperCase() + name.substring(1);

  /// Color for status chip/badge.
  Color get color {
    switch (this) {
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.unknown:
        return Colors.grey;
    }
  }

  /// True if complete/cancel actions are allowed (e.g. only for pending).
  bool get canCompleteOrCancel => this == OrderStatus.pending;
}
