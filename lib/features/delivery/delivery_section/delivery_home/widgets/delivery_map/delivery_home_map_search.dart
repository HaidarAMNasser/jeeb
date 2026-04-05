import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';

/// Google Maps–style search row (tap opens [MapSearchDialog]).
class DeliveryMapSearchBar extends StatelessWidget {
  const DeliveryMapSearchBar({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(28),
      color: Colors.white,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppPadding.p16,
            vertical: AppPadding.p12,
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: ColorManager.primary),
              SizedBox(width: AppPadding.p12),
              Expanded(
                child: Text(
                  AppTranslation.searchPlace,
                  style: getRegularStyle(
                    fontSize: AppFontSize.s14,
                    color: ColorManager.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FullscreenMapView extends StatelessWidget {
  final LatLng initialCenter;
  final Set<Marker> markers;
  final double? currentLat;
  final double? currentLng;
  final double? simulatedLat;
  final double? simulatedLng;
  final Set<Polyline> polylines;
  final BitmapDescriptor? driverMarkerIcon;

  const FullscreenMapView({
    super.key,
    required this.initialCenter,
    required this.markers,
    this.currentLat,
    this.currentLng,
    this.simulatedLat,
    this.simulatedLng,
    this.polylines = const {},
    this.driverMarkerIcon,
  });

  @override
  Widget build(BuildContext context) {
    final Set<Marker> combinedMarkers = {
      ...markers,
      if (currentLat != null && currentLng != null)
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(currentLat!, currentLng!),
          icon: driverMarkerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
          infoWindow: InfoWindow(title: AppTranslation.myLocation),
        ),
      if (simulatedLat != null && simulatedLng != null)
        Marker(
          markerId: const MarkerId('simulated_driver'),
          position: LatLng(simulatedLat!, simulatedLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(title: AppTranslation.deliveryFakeGpsMapMarker),
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslation.mapView),
        backgroundColor: ColorManager.primary,
      ),
      body: GoogleMap(
        mapType: MapType.normal,
        trafficEnabled: true,
        compassEnabled: true,
        initialCameraPosition: CameraPosition(target: initialCenter, zoom: 15),
        markers: combinedMarkers,
        polylines: polylines,
        myLocationEnabled: false,
        zoomControlsEnabled: true,
      ),
    );
  }
}

class MapSearchDialog extends StatefulWidget {
  const MapSearchDialog({super.key});

  @override
  State<MapSearchDialog> createState() => _MapSearchDialogState();
}

class _MapSearchDialogState extends State<MapSearchDialog> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppTranslation.searchPlace),
      content: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: AppTranslation.enterLocationName,
          suffixIcon: const Icon(Icons.search),
        ),
        onSubmitted: (_) => _handleSearch(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppTranslation.cancel),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSearch,
          child: _isLoading
              ? SizedBox(
                  width: AppWidth.s32,
                  height: AppHeight.s32,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(AppTranslation.search),
        ),
      ],
    );
  }

  Future<void> _handleSearch() async {
    if (_controller.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final locations = await locationFromAddress(_controller.text);
      if (locations.isNotEmpty && mounted) {
        final loc = locations.first;
        Navigator.pop(context, LatLng(loc.latitude, loc.longitude));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppTranslation.locationNotFound)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
