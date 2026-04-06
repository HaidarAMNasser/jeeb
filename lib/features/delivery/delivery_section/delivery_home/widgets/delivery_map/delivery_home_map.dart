import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'delivery_home_map_search.dart';
import 'delivery_map_chrome.dart';

class DeliveryHomeMap extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final Set<Marker> markers;

  /// Walked path from RTDB `routeHistory` (e.g. active assigned order).
  final Set<Polyline> routePolylines;

  /// Demo simulated driver position (same pipeline as real tracking).
  final double? simulatedLatitude;
  final double? simulatedLongitude;

  /// Requests a GPS fix and updates the parent-held coordinates (e.g. [recenterOnCurrentLocation]).
  final Future<void> Function()? onMyLocationPressed;

  /// Custom pin for the driver (current location); falls back to default azure marker.
  final BitmapDescriptor? driverMarkerIcon;

  const DeliveryHomeMap({
    super.key,
    this.latitude,
    this.longitude,
    this.markers = const {},
    this.routePolylines = const {},
    this.simulatedLatitude,
    this.simulatedLongitude,
    this.onMyLocationPressed,
    this.driverMarkerIcon,
  });

  @override
  State<DeliveryHomeMap> createState() => _DeliveryHomeMapState();
}

class _DeliveryHomeMapState extends State<DeliveryHomeMap> {
  GoogleMapController? _mapController;
  static const double _userLocationZoom = 15;

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
        CameraUpdate.newLatLngZoom(
          LatLng(widget.latitude!, widget.longitude!),
          _userLocationZoom,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final LatLng center = widget.latitude != null && widget.longitude != null
        ? LatLng(widget.latitude!, widget.longitude!)
        : const LatLng(30.0444, 31.2357); // Default Cairo

    final bool simulating = widget.simulatedLatitude != null &&
        widget.simulatedLongitude != null;
    final bool customDriverIcon = widget.driverMarkerIcon != null;

    final Set<Marker> combinedMarkers = {
      ...widget.markers,
      // Fake GPS: single blue driver marker follows simulated path (not a second pin).
      if (simulating)
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(
            widget.simulatedLatitude!,
            widget.simulatedLongitude!,
          ),
          icon: widget.driverMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
          anchor: customDriverIcon
              ? const Offset(0.5, 0.5)
              : const Offset(0.5, 1.0),
          infoWindow: InfoWindow(title: AppTranslation.myLocation),
        )
      else if (widget.latitude != null && widget.longitude != null)
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(widget.latitude!, widget.longitude!),
          icon: widget.driverMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
          anchor: customDriverIcon
              ? const Offset(0.5, 0.5)
              : const Offset(0.5, 1.0),
          infoWindow: InfoWindow(title: AppTranslation.myLocation),
        ),
    };

    final double initialZoom =
        widget.latitude != null && widget.longitude != null ? _userLocationZoom : 13;

    return Container(
      height: AppHeight.s250,
      margin: EdgeInsets.symmetric(horizontal: AppPadding.p16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSize.s16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              mapType: MapType.normal,
              trafficEnabled: true,
              compassEnabled: true,
              initialCameraPosition:
                  CameraPosition(target: center, zoom: initialZoom),
              markers: combinedMarkers,
              polylines: widget.routePolylines,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                _animateToLocation();
              },
            ),
            Positioned(
              left: AppPadding.p10,
              right: 52,
              top: AppPadding.p10,
              child: DeliveryMapSearchBar(
                onTap: () => _showSearchDialog(context),
              ),
            ),
            Positioned(
              top: AppPadding.p12,
              right: AppPadding.p12,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DeliveryMapChromeButton(
                    icon: Icons.fullscreen,
                    onPressed: () => _openFullscreenMap(context, center),
                  ),
                  if (widget.onMyLocationPressed != null) ...[
                    SizedBox(height: AppHeight.s8),
                    Tooltip(
                      message: AppTranslation.useMyLocation,
                      child: DeliveryMapChromeButton(
                        icon: Icons.my_location,
                        onPressed: () {
                          unawaited(widget.onMyLocationPressed!());
                        },
                      ),
                    ),
                  ],
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
          simulatedLat: widget.simulatedLatitude,
          simulatedLng: widget.simulatedLongitude,
          polylines: widget.routePolylines,
          driverMarkerIcon: widget.driverMarkerIcon,
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
