import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';

class FullscreenMapView extends StatelessWidget {
  final LatLng initialCenter;
  final Set<Marker> markers;
  final double? currentLat;
  final double? currentLng;
  final Set<Polyline> polylines;

  const FullscreenMapView({
    super.key,
    required this.initialCenter,
    required this.markers,
    this.currentLat,
    this.currentLng,
    this.polylines = const {},
  });

  @override
  Widget build(BuildContext context) {
    final Set<Marker> combinedMarkers = {
      ...markers,
      if (currentLat != null && currentLng != null)
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(currentLat!, currentLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(title: AppTranslation.myLocation),
        ),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslation.mapView),
        backgroundColor: ColorManager.primary,
      ),
      body: GoogleMap(
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
