import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'delivery_home_map_search.dart';

class DeliveryHomeMap extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final Set<Marker> markers;
  /// Walked path from RTDB `routeHistory` (e.g. active assigned order).
  final Set<Polyline> routePolylines;

  const DeliveryHomeMap({
    super.key,
    this.latitude,
    this.longitude,
    this.markers = const {},
    this.routePolylines = const {},
  });

  @override
  State<DeliveryHomeMap> createState() => _DeliveryHomeMapState();
}

class _DeliveryHomeMapState extends State<DeliveryHomeMap> {
  GoogleMapController? _mapController;

  @override
  void didUpdateWidget(covariant DeliveryHomeMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.latitude != oldWidget.latitude ||
        widget.longitude != oldWidget.longitude) {
      _animateToLocation();
    }
  }

  void _animateToLocation() {
    if (_mapController != null &&
        widget.latitude != null &&
        widget.longitude != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(widget.latitude!, widget.longitude!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = widget.latitude != null && widget.longitude != null
        ? LatLng(widget.latitude!, widget.longitude!)
        : const LatLng(30.0444, 31.2357); // Default Cairo

    final Set<Marker> combinedMarkers = {
      ...widget.markers,
      if (widget.latitude != null && widget.longitude != null)
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(widget.latitude!, widget.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(title: AppTranslation.myLocation),
        ),
    };

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
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(target: center, zoom: 13),
              markers: combinedMarkers,
              polylines: widget.routePolylines,
              myLocationEnabled: false, // Using custom orange marker instead
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
              },
            ),
            // Map Buttons
            Positioned(
              top: AppPadding.p12,
              right: AppPadding.p12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MapActionButton(
                    icon: Icons.fullscreen,
                    onPressed: () => _openFullscreenMap(context, center),
                  ),
                  SizedBox(height: AppHeight.s8),
                  _MapActionButton(
                    icon: Icons.search,
                    onPressed: () => _showSearchDialog(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openFullscreenMap(BuildContext context, LatLng center) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenMapView(
          initialCenter: center,
          markers: widget.markers,
          currentLat: widget.latitude,
          currentLng: widget.longitude,
          polylines: widget.routePolylines,
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const MapSearchDialog(),
    ).then((result) {
      if (result is LatLng && _mapController != null) {
        _mapController!.animateCamera(CameraUpdate.newLatLngZoom(result, 15));
      }
    });
  }
}

class _MapActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _MapActionButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: ColorManager.primary),
        onPressed: onPressed,
        constraints: const BoxConstraints(),
        padding: EdgeInsets.all(AppPadding.p8),
      ),
    );
  }
}
