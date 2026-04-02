import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/google_directions_service.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

/// Map with restaurant (`owner.location`) and customer drop-off (`finalLocation` or `deliveryCoordinates`).
/// Draws a driving route when both points and Directions API are available.
class DeliveryOrderDetailsRouteMap extends StatefulWidget {
  final OrderEntity order;

  const DeliveryOrderDetailsRouteMap({super.key, required this.order});

  @override
  State<DeliveryOrderDetailsRouteMap> createState() =>
      _DeliveryOrderDetailsRouteMapState();
}

class _DeliveryOrderDetailsRouteMapState
    extends State<DeliveryOrderDetailsRouteMap> {
  GoogleMapController? _controller;
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _loadRoute();
  }

  @override
  void didUpdateWidget(covariant DeliveryOrderDetailsRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final o = widget.order;
    final old = oldWidget.order;
    if (o.id != old.id ||
        o.restaurantLatitude != old.restaurantLatitude ||
        o.restaurantLongitude != old.restaurantLongitude ||
        o.dropoffLatitude != old.dropoffLatitude ||
        o.dropoffLongitude != old.dropoffLongitude) {
      setState(() => _polylines = {});
      _loadRoute();
    }
  }

  Future<void> _loadRoute() async {
    final o = widget.order;
    final oLat = o.restaurantLatitude;
    final oLng = o.restaurantLongitude;
    final dLat = o.dropoffLatitude;
    final dLng = o.dropoffLongitude;
    if (oLat == null || oLng == null || dLat == null || dLng == null) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
      }
      return;
    }
    final pts = await GoogleDirectionsService.getDrivingPolyline(
      originLat: oLat,
      originLng: oLng,
      destinationLat: dLat,
      destinationLng: dLng,
    );
    if (!mounted) return;
    if (pts != null && pts.isNotEmpty) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: PolylineId('route_${o.id}'),
            points: pts,
            color: ColorManager.primary,
            width: 5,
          ),
        };
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
  }

  Future<void> _fitCamera() async {
    final c = _controller;
    if (c == null || !mounted) return;
    final o = widget.order;
    final rLat = o.restaurantLatitude;
    final rLng = o.restaurantLongitude;
    final dLat = o.dropoffLatitude;
    final dLng = o.dropoffLongitude;
    try {
      if (rLat != null &&
          rLng != null &&
          dLat != null &&
          dLng != null) {
        final sw = LatLng(
          rLat < dLat ? rLat : dLat,
          rLng < dLng ? rLng : dLng,
        );
        final ne = LatLng(
          rLat > dLat ? rLat : dLat,
          rLng > dLng ? rLng : dLng,
        );
        await c.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(southwest: sw, northeast: ne),
            56,
          ),
        );
      } else if (dLat != null && dLng != null) {
        await c.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(dLat, dLng), 14),
        );
      } else if (rLat != null && rLng != null) {
        await c.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(rLat, rLng), 14),
        );
      }
    } catch (_) {
      // Ignore bounds errors (e.g. identical points).
    }
  }

  LatLng get _initialCenter {
    final o = widget.order;
    if (o.dropoffLatitude != null && o.dropoffLongitude != null) {
      return LatLng(o.dropoffLatitude!, o.dropoffLongitude!);
    }
    if (o.restaurantLatitude != null && o.restaurantLongitude != null) {
      return LatLng(o.restaurantLatitude!, o.restaurantLongitude!);
    }
    return const LatLng(30.0444, 31.2357);
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final restaurantName = o.owner?.restaurantName?.trim().isNotEmpty == true
        ? o.owner!.restaurantName!
        : AppTranslation.restaurantName;
    final markers = <Marker>{};
    if (o.restaurantLatitude != null && o.restaurantLongitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('restaurant'),
          position: LatLng(o.restaurantLatitude!, o.restaurantLongitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: restaurantName,
            snippet: o.pickupAddress ?? o.owner?.address,
          ),
        ),
      );
    }
    if (o.dropoffLatitude != null && o.dropoffLongitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(o.dropoffLatitude!, o.dropoffLongitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: o.displayCustomerName ?? AppTranslation.customer,
            snippet: o.displayCustomerAddressLine ?? o.deliveryAddress,
          ),
        ),
      );
    }

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
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _initialCenter,
            zoom: 12,
          ),
          markers: markers,
          polylines: _polylines,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _controller = controller;
            WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
          },
        ),
      ),
    );
  }
}
