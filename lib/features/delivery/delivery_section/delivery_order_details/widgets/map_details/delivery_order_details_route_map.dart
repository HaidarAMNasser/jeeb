import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/google_directions_service.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/location_permission_helper.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/location_service.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/maps/delivery_map_marker_bitmaps.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_map/delivery_home_map_search.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_map/delivery_map_chrome.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

/// Clean delivery map: restaurant + customer + driver with walked path.
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
  StreamSubscription<Position>? _positionSub;
  Timer? _plannedDebounce;

  Set<Polyline> _polylines = {};
  Polyline? _plannedToCustomer;
  Polyline? _liveTrailPolyline;
  final List<LatLng> _liveTrail = [];
  DateTime? _lastPlannedAt;
  double? _lastPlannedDriverLat;
  double? _lastPlannedDriverLng;
  String? _plannedCustomerKey;

  double? _driverLat;
  double? _driverLng;

  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropoffIcon;
  BitmapDescriptor? _driverIcon;

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _subscribeDriverPosition();
    _schedulePlannedCustomerRoute();
  }

  Future<void> _loadIcons() async {
    final p = await DeliveryMapMarkerBitmaps.pickup();
    final d = await DeliveryMapMarkerBitmaps.dropoff();
    final v = await DeliveryMapMarkerBitmaps.driver();
    if (!mounted) return;
    setState(() {
      _pickupIcon = p;
      _dropoffIcon = d;
      _driverIcon = v;
    });
  }

  void _subscribeDriverPosition() {
    _positionSub?.cancel();
    _positionSub = LocationService.instance
        .getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 3,
          ),
        )
        .listen(
      (pos) {
        if (!mounted) return;
        final nowPoint = LatLng(pos.latitude, pos.longitude);
        final shouldAppend = _liveTrail.isEmpty ||
            Geolocator.distanceBetween(
                  _liveTrail.last.latitude,
                  _liveTrail.last.longitude,
                  nowPoint.latitude,
                  nowPoint.longitude,
                ) >
                2.0;
        setState(() {
          _driverLat = pos.latitude;
          _driverLng = pos.longitude;
          if (shouldAppend) {
            _liveTrail.add(nowPoint);
            if (_liveTrail.length > 800) {
              _liveTrail.removeRange(0, _liveTrail.length - 800);
            }
          }
          _rebuildPolylines();
        });
        _schedulePlannedCustomerRoute();
      },
      onError: (_) {},
    );
  }

  void _schedulePlannedCustomerRoute() {
    _plannedDebounce?.cancel();
    _plannedDebounce = Timer(const Duration(milliseconds: 450), () {
      if (mounted) unawaited(_loadPlannedCustomerRoute());
    });
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
      setState(() {
        _plannedToCustomer = null;
        _liveTrail.clear();
        _liveTrailPolyline = null;
        _plannedCustomerKey = null;
        _lastPlannedAt = null;
        _lastPlannedDriverLat = null;
        _lastPlannedDriverLng = null;
        _rebuildPolylines();
      });
      _schedulePlannedCustomerRoute();
    }
  }

  Future<void> _loadPlannedCustomerRoute() async {
    final dLat = widget.order.dropoffLatitude;
    final dLng = widget.order.dropoffLongitude;
    final driverLat = _driverLat;
    final driverLng = _driverLng;
    if (dLat == null ||
        dLng == null ||
        driverLat == null ||
        driverLng == null ||
        widget.order.id.isEmpty) {
      if (_plannedToCustomer != null) {
        setState(() {
          _plannedToCustomer = null;
          _rebuildPolylines();
        });
      }
      return;
    }

    final key = '${widget.order.id}_${dLat}_$dLng';
    final movedEnough = _lastPlannedDriverLat == null ||
        _lastPlannedDriverLng == null ||
        Geolocator.distanceBetween(
              _lastPlannedDriverLat!,
              _lastPlannedDriverLng!,
              driverLat,
              driverLng,
            ) >
            8;
    final stale = _lastPlannedAt == null ||
        DateTime.now().difference(_lastPlannedAt!) > const Duration(seconds: 6);

    if (!movedEnough && !stale && _plannedCustomerKey == key) return;
    _plannedCustomerKey = key;
    final pts = await GoogleDirectionsService.getDrivingPolyline(
      originLat: driverLat,
      originLng: driverLng,
      destinationLat: dLat,
      destinationLng: dLng,
    );
    if (!mounted || _plannedCustomerKey != key) return;
    _lastPlannedAt = DateTime.now();
    _lastPlannedDriverLat = driverLat;
    _lastPlannedDriverLng = driverLng;

    final planned = (pts == null || pts.length < 2)
        ? null
        : Polyline(
            polylineId: PolylineId('planned_customer_${widget.order.id}'),
            points: pts,
            color: const Color(0xFF1A73E8).withValues(alpha: 0.82),
            width: 4,
            zIndex: 2,
            patterns: [PatternItem.dash(14), PatternItem.gap(10)],
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          );

    setState(() {
      _plannedToCustomer = planned;
      _rebuildPolylines();
    });
  }

  void _rebuildPolylines() {
    _liveTrailPolyline = _liveTrail.length < 2
        ? null
        : Polyline(
            polylineId: PolylineId('live_trail_${widget.order.id}'),
            points: List<LatLng>.from(_liveTrail),
            color: const Color(0xFFEA4335).withValues(alpha: 0.94),
            width: 6,
            zIndex: 3,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          );
    _polylines = {
      if (_plannedToCustomer != null) _plannedToCustomer!,
      if (_liveTrailPolyline != null) _liveTrailPolyline!,
    };
  }

  Future<void> _recenterOnMyLocation() async {
    Position? p = await LocationPermissionHelper.trySilentPosition();
    if (p == null) {
      var granted = await LocationPermissionHelper.isLocationPermissionGranted();
      if (!granted) {
        granted = await LocationPermissionHelper.requestLocationPermission();
      }
      if (!granted) return;
      p = await LocationPermissionHelper.getCurrentPositionWithRetries();
    }
    if (!mounted || p == null) return;
    final pos = p;
    setState(() {
      _driverLat = pos.latitude;
      _driverLng = pos.longitude;
      final nowPoint = LatLng(pos.latitude, pos.longitude);
      if (_liveTrail.isEmpty ||
          Geolocator.distanceBetween(
                _liveTrail.last.latitude,
                _liveTrail.last.longitude,
                nowPoint.latitude,
                nowPoint.longitude,
              ) >
              2.0) {
        _liveTrail.add(nowPoint);
      }
      _rebuildPolylines();
    });
    _schedulePlannedCustomerRoute();
    final c = _controller;
    if (c != null) {
      try {
        await c.animateCamera(
          CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 15),
        );
      } catch (_) {}
    }
  }

  Future<void> _fitCamera({List<LatLng> extraPoints = const []}) async {
    final c = _controller;
    if (c == null || !mounted) return;
    final o = widget.order;
    final rLat = o.restaurantLatitude;
    final rLng = o.restaurantLongitude;
    final dLat = o.dropoffLatitude;
    final dLng = o.dropoffLongitude;

    final candidates = <LatLng>[
      ...extraPoints,
      ..._liveTrail,
      if (_driverLat != null && _driverLng != null)
        LatLng(_driverLat!, _driverLng!),
      if (rLat != null && rLng != null) LatLng(rLat, rLng),
      if (dLat != null && dLng != null) LatLng(dLat, dLng),
    ];
    if (candidates.length < 2) {
      if (candidates.isEmpty) return;
      try {
        await c.animateCamera(
          CameraUpdate.newLatLngZoom(candidates.first, 14),
        );
      } catch (_) {}
      return;
    }
    double minLat = candidates.first.latitude;
    double maxLat = minLat;
    double minLng = candidates.first.longitude;
    double maxLng = minLng;
    for (final p in candidates) {
      minLat = minLat < p.latitude ? minLat : p.latitude;
      maxLat = maxLat > p.latitude ? maxLat : p.latitude;
      minLng = minLng < p.longitude ? minLng : p.longitude;
      maxLng = maxLng > p.longitude ? maxLng : p.longitude;
    }
    try {
      await c.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          56,
        ),
      );
    } catch (_) {}
  }

  void _openFullscreenRouteMap(
    BuildContext context,
    Set<Marker> markers,
    Set<Polyline> polylines,
  ) {
    final markersForFullscreen = markers
        .where((m) => m.markerId.value != 'driver')
        .toSet();
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => FullscreenMapView(
          initialCenter: _initialCenter,
          markers: markersForFullscreen,
          currentLat: _driverLat,
          currentLng: _driverLng,
          polylines: polylines,
          driverMarkerIcon: _driverIcon,
        ),
      ),
    );
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
  void dispose() {
    _plannedDebounce?.cancel();
    _positionSub?.cancel();
    super.dispose();
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
          icon: _pickupIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: restaurantName,
            snippet: o.owner?.address ?? o.pickupAddress,
          ),
        ),
      );
    }
    if (o.dropoffLatitude != null && o.dropoffLongitude != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('dropoff'),
          position: LatLng(o.dropoffLatitude!, o.dropoffLongitude!),
          icon: _dropoffIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: o.displayCustomerName ?? AppTranslation.customer,
            snippet: o.displayCustomerAddressLine ??
                o.deliveryAddress ??
                o.customer?.address,
          ),
        ),
      );
    }
    if (_driverLat != null && _driverLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: LatLng(_driverLat!, _driverLng!),
          icon: _driverIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(title: AppTranslation.myLocation),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
          child: CustomText(
            text: AppTranslation.deliveryRouteLegendWalked,
            textStyle: getRegularStyle(
              fontSize: AppFontSize.s11,
              color: ColorManager.textSecondary,
            ),
          ),
        ),
        SizedBox(height: AppHeight.s8),
        Container(
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
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _fitCamera(),
                    );
                  },
                ),
                Positioned(
                  top: AppPadding.p12,
                  right: AppPadding.p12,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DeliveryMapChromeButton(
                        icon: Icons.fullscreen,
                        onPressed: () => _openFullscreenRouteMap(
                          context,
                          markers,
                          _polylines,
                        ),
                      ),
                      SizedBox(height: AppHeight.s8),
                      Tooltip(
                        message: AppTranslation.useMyLocation,
                        child: DeliveryMapChromeButton(
                          icon: Icons.my_location,
                          onPressed: () => unawaited(_recenterOnMyLocation()),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
