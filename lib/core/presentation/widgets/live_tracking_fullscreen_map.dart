import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/core/infrastructure/realtime/route_history_point.dart';
import 'package:jeeb_app/core/presentation/maps/route_history_polyline_builder.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class LiveTrackingFullscreenMap extends StatefulWidget {
  const LiveTrackingFullscreenMap({
    super.key,
    required this.orderId,
    required this.title,
    required this.initialRouteHistory,
    this.initialDeliveryLatitude,
    this.initialDeliveryLongitude,
    this.initialDriverLatitude,
    this.initialDriverLongitude,
    this.initialStatusLabel,
    this.initialStatusOnline,
  });

  final String orderId;
  final String title;
  final List<RouteHistoryPoint> initialRouteHistory;
  final double? initialDeliveryLatitude;
  final double? initialDeliveryLongitude;
  final double? initialDriverLatitude;
  final double? initialDriverLongitude;
  final String? initialStatusLabel;
  final bool? initialStatusOnline;

  @override
  State<LiveTrackingFullscreenMap> createState() =>
      _LiveTrackingFullscreenMapState();
}

class _LiveTrackingFullscreenMapState extends State<LiveTrackingFullscreenMap> {
  final OrderStatusRtdbService _rtdb = di.sl<OrderStatusRtdbService>();

  GoogleMapController? _controller;
  StreamSubscription<int?>? _deliveryIdSub;
  StreamSubscription<DriverLiveLocation?>? _driverLocationSub;
  StreamSubscription<List<RouteHistoryPoint>>? _routeHistorySub;

  List<RouteHistoryPoint> _routeHistory = const [];
  double? _driverLatitude;
  double? _driverLongitude;
  bool _driverOnline = false;
  int? _lastDeliveryId;
  bool _didInitialCamera = false;

  LatLng? get _delivery {
    final lat = widget.initialDeliveryLatitude;
    final lng = widget.initialDeliveryLongitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  LatLng? get _driverOrTrailHead {
    final lat = _driverLatitude;
    final lng = _driverLongitude;
    if (lat != null && lng != null) return LatLng(lat, lng);
    if (_routeHistory.isEmpty) return null;
    final last = _routeHistory.last;
    return LatLng(last.lat, last.lng);
  }

  LatLng get _fallbackCamera => _driverOrTrailHead ?? _delivery!;

  @override
  void initState() {
    super.initState();
    _routeHistory = List<RouteHistoryPoint>.from(widget.initialRouteHistory);
    _driverLatitude = widget.initialDriverLatitude;
    _driverLongitude = widget.initialDriverLongitude;
    _driverOnline = widget.initialStatusOnline ?? false;
    _startRealtimeListeners();
  }

  void _startRealtimeListeners() {
    _routeHistorySub?.cancel();
    _routeHistorySub = _rtdb.watchOrderRouteHistory(widget.orderId).listen((
      points,
    ) {
      if (!mounted) return;
      setState(() => _routeHistory = points);
      _moveCamera(initial: false);
    });

    _deliveryIdSub?.cancel();
    _deliveryIdSub = _rtdb.watchOrderDeliveryId(widget.orderId).listen((
      deliveryId,
    ) {
      _listenToDriverLocation(deliveryId);
    });
  }

  void _listenToDriverLocation(int? deliveryId) {
    if (deliveryId == null || deliveryId <= 0) {
      _driverLocationSub?.cancel();
      _driverLocationSub = null;
      _lastDeliveryId = null;
      return;
    }
    if (_lastDeliveryId == deliveryId && _driverLocationSub != null) return;
    _lastDeliveryId = deliveryId;
    _driverLocationSub?.cancel();
    _driverLocationSub = _rtdb.watchDriverLiveLocation(deliveryId).listen((
      location,
    ) {
      if (!mounted || location == null) return;
      setState(() {
        _driverLatitude = location.latitude;
        _driverLongitude = location.longitude;
        _driverOnline = location.isOnline;
      });
      _moveCamera(initial: false);
    });
  }

  Set<Polyline> _buildPolylines() {
    final id = widget.orderId.trim();
    if (id.isEmpty) return {};
    final latLngs = RouteHistoryPolylineBuilder.toLatLngs(_routeHistory);
    final walked = RouteHistoryPolylineBuilder.walkedPath(
      orderId: id,
      points: latLngs,
    );
    final delivery = _delivery;
    final from = _driverOrTrailHead;
    if (delivery != null &&
        from != null &&
        _segmentMeters(from, delivery) > 12) {
      return {
        ...walked,
        Polyline(
          polylineId: PolylineId('remaining_$id'),
          points: [from, delivery],
          color: ColorManager.titlesColor.withValues(alpha: 0.42),
          width: 4,
          zIndex: 2,
          patterns: [PatternItem.dash(14), PatternItem.gap(10)],
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      };
    }
    return walked;
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    final d = _delivery;
    if (d != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('live_delivery_marker'),
          position: d,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        ),
      );
    }
    final drv = _driverOrTrailHead;
    if (drv != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('live_driver_marker'),
          position: drv,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
      );
    }
    return markers;
  }

  Future<void> _moveCamera({required bool initial}) async {
    final c = _controller;
    if (c == null || !mounted) return;
    final focus = _driverOrTrailHead ?? _delivery;
    if (focus == null) return;
    try {
      if (initial || !_didInitialCamera) {
        await c.animateCamera(CameraUpdate.newLatLngZoom(focus, 15.2));
        if (mounted) setState(() => _didInitialCamera = true);
      } else {
        await c.animateCamera(CameraUpdate.newLatLng(focus));
      }
    } catch (_) {}
  }

  static double _segmentMeters(LatLng a, LatLng b) {
    const earth = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    return 2 * earth * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
  }

  static double _rad(double d) => d * 3.141592653589793 / 180.0;

  @override
  void dispose() {
    _deliveryIdSub?.cancel();
    _driverLocationSub?.cancel();
    _routeHistorySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chipColor =
        _driverOnline ? ColorManager.defaultBlue : Colors.orange;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: CustomText(
                text: widget.title,
                textStyle: getSemiBoldStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.defaultWhite,
                ),
              ),
            ),
            if (widget.initialStatusLabel != null &&
                widget.initialStatusLabel!.trim().isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: chipColor.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: chipColor.withValues(alpha: 0.45)),
                ),
                child: CustomText(
                  text: widget.initialStatusLabel!,
                  textStyle: getMediumStyle(
                    fontSize: AppFontSize.s11,
                    color: chipColor,
                  ),
                ),
              ),
          ],
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _fallbackCamera,
          zoom: 15.2,
        ),
        markers: _buildMarkers(),
        polylines: _buildPolylines(),
        myLocationButtonEnabled: false,
        mapToolbarEnabled: false,
        compassEnabled: true,
        onMapCreated: (controller) {
          _controller = controller;
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            await _moveCamera(initial: true);
          });
        },
      ),
    );
  }
}
