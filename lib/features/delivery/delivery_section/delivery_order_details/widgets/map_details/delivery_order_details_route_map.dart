import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/core/infrastructure/realtime/route_history_point.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/google_directions_service.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/location_permission_helper.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/location_service.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/maps/delivery_map_marker_bitmaps.dart';
import 'package:jeeb_app/core/presentation/maps/route_history_polyline_builder.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_map/delivery_home_map_search.dart';
import 'package:jeeb_app/features/delivery/delivery_section/delivery_home/widgets/delivery_map/delivery_map_chrome.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

/// Restaurant + drop-off + driver, Directions legs (dashed), walked path from RTDB.
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
  StreamSubscription<List<RouteHistoryPoint>>? _routeHistorySub;
  StreamSubscription<Position>? _positionSub;
  Timer? _plannedDebounce;

  Set<Polyline> _polylines = {};
  Polyline? _plannedDropoff;
  Polyline? _plannedPickup;
  String? _dropoffKey;

  DateTime? _lastPickupFetchAt;
  double? _lastPickupDriverLat;
  double? _lastPickupDriverLng;

  double? _driverLat;
  double? _driverLng;

  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropoffIcon;
  BitmapDescriptor? _driverIcon;

  OrderStatusRtdbService get _rtdb => di.sl<OrderStatusRtdbService>();

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _subscribeRouteHistory();
    _subscribeDriverPosition();
    _schedulePlannedRoutes();
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
            distanceFilter: 80,
          ),
        )
        .listen(
      (pos) {
        if (!mounted) return;
        setState(() {
          _driverLat = pos.latitude;
          _driverLng = pos.longitude;
        });
        _schedulePlannedRoutes();
      },
      onError: (_) {},
    );
  }

  void _schedulePlannedRoutes() {
    _plannedDebounce?.cancel();
    _plannedDebounce = Timer(const Duration(milliseconds: 650), () {
      if (mounted) unawaited(_loadPlannedRoutes());
    });
  }

  @override
  void didUpdateWidget(covariant DeliveryOrderDetailsRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final o = widget.order;
    final old = oldWidget.order;
    if (o.id != old.id) {
      _routeHistorySub?.cancel();
      _subscribeRouteHistory();
    }
    if (o.id != old.id ||
        o.restaurantLatitude != old.restaurantLatitude ||
        o.restaurantLongitude != old.restaurantLongitude ||
        o.dropoffLatitude != old.dropoffLatitude ||
        o.dropoffLongitude != old.dropoffLongitude) {
      setState(() {
        _plannedDropoff = null;
        _plannedPickup = null;
        _dropoffKey = null;
        _polylines = {..._walkedOnlyPolylines(_polylines)};
      });
      _schedulePlannedRoutes();
    }
  }

  Set<Polyline> _walkedOnlyPolylines(Set<Polyline> all) {
    return all.where((p) => p.polylineId.value.startsWith('walked_')).toSet();
  }

  void _subscribeRouteHistory() {
    _routeHistorySub?.cancel();
    _routeHistorySub = _rtdb.watchOrderRouteHistory(widget.order.id).listen(
      (points) {
        if (!mounted) return;
        final latLngs = RouteHistoryPolylineBuilder.toLatLngs(points);
        final walked = RouteHistoryPolylineBuilder.walkedPath(
          orderId: widget.order.id,
          points: latLngs,
        );
        setState(() {
          _polylines = {
            if (_plannedPickup != null) _plannedPickup!,
            if (_plannedDropoff != null) _plannedDropoff!,
            ...walked,
          };
        });
        _fitCamera(extraPoints: latLngs);
      },
    );
  }

  Future<void> _loadPlannedRoutes() async {
    final o = widget.order;
    final rLat = o.restaurantLatitude;
    final rLng = o.restaurantLongitude;
    final dLat = o.dropoffLatitude;
    final dLng = o.dropoffLongitude;
    if (rLat == null || rLng == null || dLat == null || dLng == null) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
      }
      return;
    }

    final dropKey = '${o.id}_drop_${rLat}_${rLng}_${dLat}_$dLng';
    Polyline? newDropoff = _plannedDropoff;
    if (_dropoffKey != dropKey) {
      _dropoffKey = dropKey;
      final pts = await GoogleDirectionsService.getDrivingPolyline(
        originLat: rLat,
        originLng: rLng,
        destinationLat: dLat,
        destinationLng: dLng,
      );
      if (!mounted) return;
      if (_dropoffKey != dropKey) return;
      newDropoff = pts == null || pts.isEmpty
          ? null
          : RouteHistoryPolylineBuilder.plannedDropoffLeg(
              orderId: o.id,
              points: pts,
            );
    }

    final driverLat = _driverLat;
    final driverLng = _driverLng;
    Polyline? newPickup = _plannedPickup;

    if (driverLat != null && driverLng != null) {
      final needPickup = _plannedPickup == null ||
          _lastPickupFetchAt == null ||
          _lastPickupDriverLat == null ||
          _lastPickupDriverLng == null ||
          DateTime.now().difference(_lastPickupFetchAt!) >
              const Duration(seconds: 40) ||
          Geolocator.distanceBetween(
                _lastPickupDriverLat!,
                _lastPickupDriverLng!,
                driverLat,
                driverLng,
              ) >
              120;

      if (needPickup) {
        final pts = await GoogleDirectionsService.getDrivingPolyline(
          originLat: driverLat,
          originLng: driverLng,
          destinationLat: rLat,
          destinationLng: rLng,
        );
        if (!mounted) return;
        if (pts == null || pts.isEmpty) {
          newPickup = null;
        } else {
          newPickup = RouteHistoryPolylineBuilder.plannedPickupLeg(
            orderId: o.id,
            points: pts,
          );
        }
        _lastPickupFetchAt = DateTime.now();
        _lastPickupDriverLat = driverLat;
        _lastPickupDriverLng = driverLng;
      }
    } else {
      newPickup = null;
      _lastPickupFetchAt = null;
      _lastPickupDriverLat = null;
      _lastPickupDriverLng = null;
    }

    if (!mounted) return;
    setState(() {
      _plannedDropoff = newDropoff;
      _plannedPickup = newPickup;
      final walked = _walkedOnlyPolylines(_polylines);
      _polylines = {
        if (_plannedPickup != null) _plannedPickup!,
        if (_plannedDropoff != null) _plannedDropoff!,
        ...walked,
      };
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
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
    });
    _schedulePlannedRoutes();
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

  void _showRouteMapSearch() {
    showDialog<dynamic>(
      context: context,
      builder: (dialogContext) => const MapSearchDialog(),
    ).then((result) {
      if (result is LatLng && _controller != null) {
        _controller!.animateCamera(
          CameraUpdate.newLatLngZoom(result, 15),
        );
      }
    });
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
    _routeHistorySub?.cancel();
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
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
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
                  left: AppPadding.p10,
                  right: 52,
                  top: AppPadding.p10,
                  child: DeliveryMapSearchBar(
                    onTap: _showRouteMapSearch,
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
