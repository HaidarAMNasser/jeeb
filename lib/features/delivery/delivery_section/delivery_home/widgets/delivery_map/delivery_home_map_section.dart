import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_map/delivery_home_map.dart';

/// Map + simulated position listenable; pure display.
class DeliveryHomeMapSection extends StatelessWidget {
  const DeliveryHomeMapSection({
    super.key,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.simulatedPosition,
    required this.markers,
    required this.routePolylines,
    required this.onMyLocationPressed,
    this.driverMarkerIcon,
  });

  final double? currentLatitude;
  final double? currentLongitude;
  final ValueListenable<LatLng?> simulatedPosition;
  final Set<Marker> markers;
  final Set<Polyline> routePolylines;
  final Future<void> Function() onMyLocationPressed;
  final BitmapDescriptor? driverMarkerIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppPadding.p16),
      child: ValueListenableBuilder<LatLng?>(
        valueListenable: simulatedPosition,
        builder: (context, sim, _) {
          return DeliveryHomeMap(
            latitude: currentLatitude,
            longitude: currentLongitude,
            simulatedLatitude: sim?.latitude,
            simulatedLongitude: sim?.longitude,
            markers: markers,
            routePolylines: routePolylines,
            onMyLocationPressed: onMyLocationPressed,
            driverMarkerIcon: driverMarkerIcon,
          );
        },
      ),
    );
  }
}
