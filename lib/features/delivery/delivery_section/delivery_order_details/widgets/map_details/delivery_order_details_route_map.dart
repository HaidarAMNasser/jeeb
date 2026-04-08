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

/// Driver-side order details map:
/// - always show restaurant + customer markers
/// - seed driver location immediately
/// - keep a live local red trail from current session only
/// - keep a clean Google route from driver -> customer
class DeliveryOrderDetailsRouteMap extends StatefulWidget {
  const DeliveryOrderDetailsRouteMap({super.key, required this.order});

  final OrderEntity order;

  @override
  State<DeliveryOrderDetailsRouteMap> createState() =>
      _DeliveryOrderDetailsRouteMapState();
}

class _DeliveryOrderDetailsRouteMapState
    extends State<DeliveryOrderDetailsRouteMap> {
  GoogleMapController? _controller;
  StreamSubscription<List<RouteHistoryPoint>>? _routeHistorySub;
  StreamSubscription<Position>? _positionSub;
  Timer? _guideRouteDebounce;

  BitmapDescriptor? _restaurantIcon;
  BitmapDescriptor? _customerIcon;
  BitmapDescriptor? _driverIcon;

  LatLng? _driverPoint;
  final List<LatLng> _localTrailPoints = [];
  List<LatLng> _remoteTrailPoints = const [];

  Polyline? _guidePolyline;
  Polyline? _trailPolyline;

  DateTime? _lastGuideFetchAt;
  LatLng? _lastGuideOrigin;
  bool _didInitialCameraFit = false;

  static const double _trailAppendMeters = 1.5;
  static const double _guideRefreshMeters = 5.0;

  OrderStatusRtdbService get _rtdb => di.sl<OrderStatusRtdbService>();

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  @override
  void didUpdateWidget(covariant DeliveryOrderDetailsRouteMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final o = widget.order;
    final old = oldWidget.order;
    if (o.id != old.id) {
      _subscribeRouteHistory();
    }
    if (o.id != old.id ||
        o.restaurantLatitude != old.restaurantLatitude ||
        o.restaurantLongitude != old.restaurantLongitude ||
        o.dropoffLatitude != old.dropoffLatitude ||
        o.dropoffLongitude != old.dropoffLongitude) {
      _resetRouteState();
      _scheduleGuideRouteRefresh();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitInitialCamera();
      });
    }
  }

  Future<void> _bootstrap() async {
    await _loadIcons();
    _subscribeRouteHistory();
    await _seedInitialDriverLocation();
    _startDriverStream();
    if (mounted) {
      _scheduleGuideRouteRefresh();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fitInitialCamera();
      });
    }
  }

  Future<void> _loadIcons() async {
    final restaurant = await DeliveryMapMarkerBitmaps.pickup();
    final customer = await DeliveryMapMarkerBitmaps.dropoff();
    final driver = await DeliveryMapMarkerBitmaps.driver();
    if (!mounted) return;
    setState(() {
      _restaurantIcon = restaurant;
      _customerIcon = customer;
      _driverIcon = driver;
    });
  }

  Future<void> _seedInitialDriverLocation() async {
    Position? position = await LocationPermissionHelper.trySilentPosition();
    if (position == null) {
      var granted = await LocationPermissionHelper.isLocationPermissionGranted();
      if (!granted) {
        granted = await LocationPermissionHelper.requestLocationPermission();
      }
      if (!granted) return;
      position = await LocationPermissionHelper.getCurrentPositionWithRetries();
    }
    if (!mounted || position == null) return;
    _applyDriverPosition(
      LatLng(position.latitude, position.longitude),
      followOnMap: false,
    );
  }

  void _subscribeRouteHistory() {
    _routeHistorySub?.cancel();
    _routeHistorySub = _rtdb.watchOrderRouteHistory(widget.order.id).listen(
      (points) {
        if (!mounted) return;
        setState(() {
          _remoteTrailPoints = RouteHistoryPolylineBuilder.toLatLngs(points);
          _rebuildTrailPolyline();
        });
        _fitInitialCamera();
      },
      onError: (_) {},
    );
  }

  void _startDriverStream() {
    _positionSub?.cancel();
    _positionSub = LocationService.instance
        .getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 2,
          ),
        )
        .listen(
          (pos) {
            if (!mounted) return;
            _applyDriverPosition(
              LatLng(pos.latitude, pos.longitude),
              followOnMap: true,
            );
          },
          onError: (_) {},
        );
  }

  void _applyDriverPosition(
    LatLng next, {
    required bool followOnMap,
  }) {
    final prev = _driverPoint;
    final movedEnoughForTrail = prev == null ||
        Geolocator.distanceBetween(
              prev.latitude,
              prev.longitude,
              next.latitude,
              next.longitude,
            ) >=
            _trailAppendMeters;

    setState(() {
      _driverPoint = next;
      if (_localTrailPoints.isEmpty || movedEnoughForTrail) {
        _localTrailPoints.add(next);
        if (_localTrailPoints.length > 600) {
          _localTrailPoints.removeRange(0, _localTrailPoints.length - 600);
        }
      }
      _rebuildTrailPolyline();
    });

    _scheduleGuideRouteRefresh();
    if (followOnMap) {
      _keepDriverAndCustomerVisible();
    }
  }

  void _rebuildTrailPolyline() {
    final points = _effectiveTrailPoints();
    _trailPolyline = points.length < 2
        ? null
        : Polyline(
            polylineId: PolylineId('live_trail_${widget.order.id}'),
            points: points,
            color: const Color(0xFFEA4335).withValues(alpha: 0.95),
            width: 6,
            zIndex: 3,
            jointType: JointType.round,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          );
  }

  List<LatLng> _effectiveTrailPoints() {
    if (_remoteTrailPoints.isEmpty) {
      return List<LatLng>.from(_localTrailPoints);
    }
    final merged = List<LatLng>.from(_remoteTrailPoints);
    for (final point in _localTrailPoints) {
      final last = merged.isEmpty ? null : merged.last;
      if (last == null) {
        merged.add(point);
        continue;
      }
      final meters = Geolocator.distanceBetween(
        last.latitude,
        last.longitude,
        point.latitude,
        point.longitude,
      );
      if (meters >= _trailAppendMeters && meters < 80) {
        merged.add(point);
      }
    }
    return merged;
  }

  void _scheduleGuideRouteRefresh() {
    _guideRouteDebounce?.cancel();
    _guideRouteDebounce = Timer(const Duration(milliseconds: 350), () {
      if (mounted) unawaited(_refreshGuideRoute());
    });
  }

  Future<void> _refreshGuideRoute() async {
    final origin = _driverPoint;
    final destination = _customerPoint;
    if (origin == null || destination == null || widget.order.id.isEmpty) {
      if (_guidePolyline != null && mounted) {
        setState(() => _guidePolyline = null);
      }
      return;
    }

    final movedEnough = _lastGuideOrigin == null ||
        Geolocator.distanceBetween(
              _lastGuideOrigin!.latitude,
              _lastGuideOrigin!.longitude,
              origin.latitude,
              origin.longitude,
            ) >=
            _guideRefreshMeters;
    final staleEnough = _lastGuideFetchAt == null ||
        DateTime.now().difference(_lastGuideFetchAt!) >
            const Duration(seconds: 6);

    if (!movedEnough && !staleEnough) return;

    final points = await GoogleDirectionsService.getDrivingPolyline(
      originLat: origin.latitude,
      originLng: origin.longitude,
      destinationLat: destination.latitude,
      destinationLng: destination.longitude,
    );
    if (!mounted) return;

    _lastGuideOrigin = origin;
    _lastGuideFetchAt = DateTime.now();

    setState(() {
      _guidePolyline = (points == null || points.length < 2)
          ? null
          : Polyline(
              polylineId: PolylineId('guide_customer_${widget.order.id}'),
              points: points,
              color: const Color(0xFF1A73E8).withValues(alpha: 0.86),
              width: 4,
              zIndex: 2,
              patterns: [PatternItem.dash(14), PatternItem.gap(10)],
              jointType: JointType.round,
              startCap: Cap.roundCap,
              endCap: Cap.roundCap,
            );
    });
  }

  Future<void> _recenterOnMyLocation() async {
    Position? position = await LocationPermissionHelper.trySilentPosition();
    if (position == null) {
      var granted = await LocationPermissionHelper.isLocationPermissionGranted();
      if (!granted) {
        granted = await LocationPermissionHelper.requestLocationPermission();
      }
      if (!granted) return;
      position = await LocationPermissionHelper.getCurrentPositionWithRetries();
    }
    if (!mounted || position == null) return;
    _applyDriverPosition(
      LatLng(position.latitude, position.longitude),
      followOnMap: true,
    );
  }

  LatLng? get _restaurantPoint {
    final lat = widget.order.restaurantLatitude;
    final lng = widget.order.restaurantLongitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  LatLng? get _customerPoint {
    final lat = widget.order.dropoffLatitude;
    final lng = widget.order.dropoffLongitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  LatLng get _initialCenter {
    return _customerPoint ??
        _restaurantPoint ??
        _driverPoint ??
        const LatLng(30.0444, 31.2357);
  }

  Set<Polyline> get _mapPolylines => {
        if (_guidePolyline != null) _guidePolyline!,
        if (_trailPolyline != null) _trailPolyline!,
      };

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    final restaurant = _restaurantPoint;
    final customer = _customerPoint;
    final driver = _driverPoint;
    final restaurantName =
        widget.order.owner?.restaurantName?.trim().isNotEmpty == true
            ? widget.order.owner!.restaurantName!
            : AppTranslation.restaurantName;

    if (restaurant != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('restaurant'),
          position: restaurant,
          icon: _restaurantIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: InfoWindow(
            title: restaurantName,
            snippet: widget.order.owner?.address ?? widget.order.pickupAddress,
          ),
        ),
      );
    }

    if (customer != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('customer'),
          position: customer,
          icon: _customerIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: widget.order.displayCustomerName ?? AppTranslation.customer,
            snippet: widget.order.displayCustomerAddressLine ??
                widget.order.deliveryAddress ??
                widget.order.customer?.address,
          ),
        ),
      );
    }

    if (driver != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: driver,
          icon: _driverIcon ??
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          anchor: const Offset(0.5, 0.5),
          flat: true,
          infoWindow: InfoWindow(title: AppTranslation.myLocation),
        ),
      );
    }

    return markers;
  }

  void _resetRouteState() {
    _didInitialCameraFit = false;
    _guidePolyline = null;
    _trailPolyline = null;
    _localTrailPoints.clear();
    _remoteTrailPoints = const [];
    _lastGuideFetchAt = null;
    _lastGuideOrigin = null;
  }

  Future<void> _fitInitialCamera() async {
    if (_didInitialCameraFit) return;
    final controller = _controller;
    if (controller == null || !mounted) return;

    final points = <LatLng>[
      if (_restaurantPoint != null) _restaurantPoint!,
      if (_customerPoint != null) _customerPoint!,
      if (_driverPoint != null) _driverPoint!,
      ..._remoteTrailPoints,
    ];
    if (points.isEmpty) return;

    _didInitialCameraFit = true;
    await _animateBounds(points, padding: 72, fallbackZoom: 14.5);
  }

  Future<void> _keepDriverAndCustomerVisible() async {
    final controller = _controller;
    if (controller == null || !mounted) return;
    final driver = _driverPoint;
    final customer = _customerPoint;
    if (driver == null) return;

    if (customer == null) {
      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(driver, 16),
        );
      } catch (_) {}
      return;
    }

    await _animateBounds([driver, customer], padding: 120, fallbackZoom: 15.5);
  }

  Future<void> _animateBounds(
    List<LatLng> points, {
    required double padding,
    required double fallbackZoom,
  }) async {
    final controller = _controller;
    if (controller == null || !mounted || points.isEmpty) return;

    if (points.length == 1) {
      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, fallbackZoom),
        );
      } catch (_) {}
      return;
    }

    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points.skip(1)) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(minLat, minLng),
            northeast: LatLng(maxLat, maxLng),
          ),
          padding,
        ),
      );
    } catch (_) {
      try {
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(points.first, fallbackZoom),
        );
      } catch (_) {}
    }
  }

  void _openFullscreenMap(BuildContext context, Set<Marker> markers) {
    final staticMarkers = markers
        .where((m) => m.markerId.value != 'driver')
        .toSet();
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FullscreenMapView(
          initialCenter: _initialCenter,
          markers: staticMarkers,
          currentLat: _driverPoint?.latitude,
          currentLng: _driverPoint?.longitude,
          polylines: _mapPolylines,
          driverMarkerIcon: _driverIcon,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _guideRouteDebounce?.cancel();
    _routeHistorySub?.cancel();
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final markers = _buildMarkers();

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
                    zoom: 13,
                  ),
                  markers: markers,
                  polylines: _mapPolylines,
                  myLocationEnabled: false,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  onMapCreated: (controller) {
                    _controller = controller;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _fitInitialCamera();
                    });
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
                        onPressed: () => _openFullscreenMap(context, markers),
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
