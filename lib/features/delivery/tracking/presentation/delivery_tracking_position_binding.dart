import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

/// Exposes [forward] so [DeliveryHomePage]'s GPS stream can feed
/// [DeliveryOrderLocationReporter] without a second location subscription.
class DeliveryTrackingPositionBinding extends InheritedWidget {
  const DeliveryTrackingPositionBinding({
    super.key,
    required this.forward,
    required super.child,
  });

  final void Function(Position position) forward;

  static DeliveryTrackingPositionBinding? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<DeliveryTrackingPositionBinding>();
  }

  @override
  bool updateShouldNotify(DeliveryTrackingPositionBinding oldWidget) {
    return forward != oldWidget.forward;
  }
}
