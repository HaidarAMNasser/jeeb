import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:latlong2/latlong.dart';

class DeliveryHomeMap extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final List<Marker> markers;

  const DeliveryHomeMap({
    super.key,
    this.latitude,
    this.longitude,
    this.markers = const [],
  });

  @override
  Widget build(BuildContext context) {
    final LatLng center = latitude != null && longitude != null
        ? LatLng(latitude!, longitude!)
        : const LatLng(30.0444, 31.2357); // Default Cairo

    return Container(
      height: AppHeight.s250,
      margin: EdgeInsets.symmetric(horizontal: AppPadding.p16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.s16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSize.s16),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 13,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.jeeb.app',
              // Dark mode style for the map if possible, or just standard
              tileBuilder: (context, tileWidget, tile) {
                return ColorFiltered(
                  colorFilter: ColorFilter.matrix([
                    -0.2126, -0.7152, -0.0722, 0, 255, // Red
                    -0.2126, -0.7152, -0.0722, 0, 255, // Green
                    -0.2126, -0.7152, -0.0722, 0, 255, // Blue
                    0, 0, 0, 1, 0, // Alpha
                  ]),
                  child: tileWidget,
                );
              },
            ),
            if (markers.isNotEmpty) MarkerLayer(markers: markers),
          ],
        ),
      ),
    );
  }
}
