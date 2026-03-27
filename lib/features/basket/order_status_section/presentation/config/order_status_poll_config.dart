/// Polling while [OrderStatusPage] is open (no WebSocket on backend).
/// Change [interval] only here so behavior stays predictable app-wide.
class OrderStatusPollConfig {
  OrderStatusPollConfig._();

  /// How often to refetch order details. Lower feels more “live” but costs more requests.
  static const Duration interval = Duration(seconds: 10);
}
