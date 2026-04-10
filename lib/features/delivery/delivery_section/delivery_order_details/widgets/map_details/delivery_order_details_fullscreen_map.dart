import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

class DeliveryOrderDetailsFullscreenMap extends StatefulWidget {
  const DeliveryOrderDetailsFullscreenMap({
    super.key,
    required this.order,
    required this.initialCenter,
    required this.staticMarkers,
    required this.driverPointListenable,
    required this.polylinesListenable,
    required this.driverMarkerIcon,
  });

  final OrderEntity order;
  final LatLng initialCenter;
  final Set<Marker> staticMarkers;
  final ValueListenable<LatLng?> driverPointListenable;
  final ValueListenable<Set<Polyline>> polylinesListenable;
  final BitmapDescriptor? driverMarkerIcon;

  @override
  State<DeliveryOrderDetailsFullscreenMap> createState() =>
      _DeliveryOrderDetailsFullscreenMapState();
}

class _DeliveryOrderDetailsFullscreenMapState
    extends State<DeliveryOrderDetailsFullscreenMap> {
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    widget.driverPointListenable.addListener(_onDriverPointChanged);
  }

  @override
  void dispose() {
    widget.driverPointListenable.removeListener(_onDriverPointChanged);
    super.dispose();
  }

  LatLng? get _customerPoint {
    final lat = widget.order.dropoffLatitude;
    final lng = widget.order.dropoffLongitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  void _onDriverPointChanged() {
    final controller = _controller;
    final driver = widget.driverPointListenable.value;
    final customer = _customerPoint;
    if (controller == null || driver == null || !mounted) return;

    if (customer == null) {
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(driver, 16),
      );
      return;
    }

    final minLat = driver.latitude < customer.latitude
        ? driver.latitude
        : customer.latitude;
    final maxLat = driver.latitude > customer.latitude
        ? driver.latitude
        : customer.latitude;
    final minLng = driver.longitude < customer.longitude
        ? driver.longitude
        : customer.longitude;
    final maxLng = driver.longitude > customer.longitude
        ? driver.longitude
        : customer.longitude;

    controller.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        120,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppTranslation.mapView),
        backgroundColor: ColorManager.primary,
      ),
      body: AnimatedBuilder(
        animation: Listenable.merge([
          widget.driverPointListenable,
          widget.polylinesListenable,
        ]),
        builder: (context, _) {
          final driver = widget.driverPointListenable.value;
          final markers = {
            ...widget.staticMarkers,
            if (driver != null)
              Marker(
                markerId: const MarkerId('driver'),
                position: driver,
                icon: widget.driverMarkerIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                anchor: const Offset(0.5, 0.5),
                flat: true,
                infoWindow: InfoWindow(title: AppTranslation.myLocation),
              ),
          };

          return GoogleMap(
            mapType: MapType.normal,
            trafficEnabled: true,
            compassEnabled: true,
            initialCameraPosition: CameraPosition(
              target: widget.initialCenter,
              zoom: 15,
            ),
            markers: markers,
            polylines: widget.polylinesListenable.value,
            myLocationEnabled: false,
            zoomControlsEnabled: true,
            onMapCreated: (controller) {
              _controller = controller;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _onDriverPointChanged();
              });
            },
          );
        },
      ),
    );
  }
}
