import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_map/delivery_home_map.dart';

/// Home map display section.
class DeliveryHomeMapSection extends StatelessWidget {
  const DeliveryHomeMapSection({
    super.key,
    required this.currentLatitude,
    required this.currentLongitude,
    required this.markers,
    required this.routePolylines,
    required this.onMyLocationPressed,
    this.driverMarkerIcon,
  });

  final double? currentLatitude;
  final double? currentLongitude;
  final Set<Marker> markers;
  final Set<Polyline> routePolylines;
  final Future<void> Function() onMyLocationPressed;
  final BitmapDescriptor? driverMarkerIcon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppPadding.p16),
      child: DeliveryHomeMap(
        latitude: currentLatitude,
        longitude: currentLongitude,
        markers: markers,
        routePolylines: routePolylines,
        onMyLocationPressed: onMyLocationPressed,
        driverMarkerIcon: driverMarkerIcon,
      ),
    );
  }
}
