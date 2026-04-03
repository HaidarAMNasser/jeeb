import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/infrastructure/di/dependency_injection.dart' as di;
import 'package:jeeb_app/core/infrastructure/realtime/order_status_rtdb_service.dart';
import 'package:jeeb_app/core/infrastructure/realtime/route_history_point.dart';
import 'package:jeeb_app/core/infrastructure/services/location_services/google_directions_service.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/maps/route_history_polyline_builder.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/delivery/order/order_details/domain/entities/order_entity.dart';

/// Restaurant + drop-off markers, optional planned road (dashed), and live **walked path**
/// from Firebase `routeHistory` (gradient segments). See `Firebase_Realtime_Database.md`.
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
  Set<Polyline> _polylines = {};
  Polyline? _plannedPolyline;

  OrderStatusRtdbService get _rtdb => di.sl<OrderStatusRtdbService>();

  @override
  void initState() {
    super.initState();
    _subscribeRouteHistory();
    _loadPlannedRoute();
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
        _plannedPolyline = null;
        _polylines = {..._walkedOnlyPolylines(_polylines)};
      });
      _loadPlannedRoute();
    }
  }

  /// Keep walked polylines when clearing planned route during rebuild.
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
            if (_plannedPolyline != null) _plannedPolyline!,
            ...walked,
          };
        });
        _fitCamera(extraPoints: latLngs);
      },
    );
  }

  Future<void> _loadPlannedRoute() async {
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
      final planned = RouteHistoryPolylineBuilder.plannedRoute(
        orderId: o.id,
        points: pts,
      );
      setState(() {
        _plannedPolyline = planned;
        final walked = _walkedOnlyPolylines(_polylines);
        _polylines = {
          if (planned != null) planned,
          ...walked,
        };
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitCamera());
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
    } catch (_) {
      // Identical / invalid bounds.
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
  void dispose() {
    _routeHistorySub?.cancel();
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
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
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
          infoWindow: InfoWindow(
            title: o.displayCustomerName ?? AppTranslation.customer,
            snippet:
                o.displayCustomerAddressLine ?? o.deliveryAddress ?? o.customer?.address,
          ),
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
        ),
      ],
    );
  }
}
