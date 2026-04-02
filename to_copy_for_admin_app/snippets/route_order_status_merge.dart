// Add next to your other route helpers (before AppRouter class or as a top-level function):

double? routeArgAsDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

// In generateRoute switch, add imports:
// import '.../order_status_rtdb_service.dart';
// import '.../order_status_bloc.dart';
// import '.../order_status_page.dart';
// import '.../order_status.dart' for OrderStatus enum (entity);

// Case for order tracking:
      case Routes.orderStatus:
        final osArgs = settings.arguments as Map<String, dynamic>?;
        final orderStatusId = osArgs?['orderId'] as String? ?? '';
        final initialStatus = OrderStatus.fromString(
          osArgs?['initialStatus'] as String?,
        );
        final deliveryLat = routeArgAsDouble(osArgs?['deliveryLatitude']);
        final deliveryLng = routeArgAsDouble(osArgs?['deliveryLongitude']);
        if (orderStatusId.isEmpty) {
          return _buildRoute(
            Scaffold(body: Center(child: Text('Order ID not provided'))),
            settings,
          );
        }
        return _buildRouteWithBlocs(
          const OrderStatusPage(),
          settings,
          providers: [
            BlocProvider<OrderStatusBloc>(
              create: (_) => OrderStatusBloc(
                orderId: orderStatusId,
                initialStatus: initialStatus,
                deliveryLatitude: deliveryLat,
                deliveryLongitude: deliveryLng,
                orderStatusRtdb: di.sl<OrderStatusRtdbService>(),
              ),
            ),
          ],
        );
