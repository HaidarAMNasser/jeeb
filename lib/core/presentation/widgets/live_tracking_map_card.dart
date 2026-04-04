import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/infrastructure/realtime/route_history_point.dart';
import 'package:jeeb_app/core/presentation/maps/route_history_polyline_builder.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Live map: driver-centered camera, walked path from RTDB `routeHistory`, dashed
/// segment to drop-off when both ends are known.
class LiveTrackingMapCard extends StatefulWidget {
  LiveTrackingMapCard({
    super.key,
    required this.orderId,
    required this.title,
    required this.routeHistory,
    this.deliveryLatitude,
    this.deliveryLongitude,
    this.driverLatitude,
    this.driverLongitude,
    this.statusLabel,
    this.statusOnline,
    this.height = 220,
  }) : assert(
          (deliveryLatitude != null && deliveryLongitude != null) ||
              (driverLatitude != null && driverLongitude != null) ||
              routeHistory.isNotEmpty,
        );

  final String orderId;
  final String title;
  final List<RouteHistoryPoint> routeHistory;
  final double? deliveryLatitude;
  final double? deliveryLongitude;
  final double? driverLatitude;
  final double? driverLongitude;
  final String? statusLabel;
  final bool? statusOnline;
  final double height;

  @override
  State<LiveTrackingMapCard> createState() => _LiveTrackingMapCardState();
}

class _LiveTrackingMapCardState extends State<LiveTrackingMapCard> {
  GoogleMapController? _controller;
  bool _didInitialCamera = false;

  LatLng? get _delivery {
    final lat = widget.deliveryLatitude;
    final lng = widget.deliveryLongitude;
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  /// Prefer live driver node; else last routeHistory point (per Firebase doc).
  LatLng? get _driverOrTrailHead {
    final lat = widget.driverLatitude;
    final lng = widget.driverLongitude;
    if (lat != null && lng != null) return LatLng(lat, lng);
    final pts = widget.routeHistory;
    if (pts.isEmpty) return null;
    final last = pts.last;
    return LatLng(last.lat, last.lng);
  }

  LatLng get _fallbackCamera {
    return _driverOrTrailHead ?? _delivery!;
  }

  Set<Polyline> _buildPolylines() {
    final id = widget.orderId.trim();
    if (id.isEmpty) return {};
    final latLngs = RouteHistoryPolylineBuilder.toLatLngs(widget.routeHistory);
    final walked = RouteHistoryPolylineBuilder.walkedPath(orderId: id, points: latLngs);
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

  static double _segmentMeters(LatLng a, LatLng b) {
    const earth = 6371000.0;
    final dLat = _rad(b.latitude - a.latitude);
    final dLng = _rad(b.longitude - a.longitude);
    final lat1 = _rad(a.latitude);
    final lat2 = _rad(b.latitude);
    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return 2 * earth * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
  }

  static double _rad(double d) => d * 3.141592653589793 / 180.0;

  Future<void> _moveCamera({required bool initial}) async {
    final c = _controller;
    if (c == null || !mounted) return;
    final focus = _driverOrTrailHead ?? _delivery;
    if (focus == null) return;
    try {
      if (initial) {
        await c.animateCamera(CameraUpdate.newLatLngZoom(focus, 15.2));
      } else {
        await c.animateCamera(CameraUpdate.newLatLng(focus));
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant LiveTrackingMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.driverLatitude != widget.driverLatitude ||
        oldWidget.driverLongitude != widget.driverLongitude ||
        oldWidget.routeHistory.length != widget.routeHistory.length) {
      if (_didInitialCamera) {
        _moveCamera(initial: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chipColor =
        (widget.statusOnline ?? false) ? ColorManager.defaultBlue : Colors.orange;
    final markers = <Marker>{};
    final d = _delivery;
    if (d != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('live_delivery_marker'),
          position: d,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }
    final drv = _driverOrTrailHead;
    if (drv != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('live_driver_marker'),
          position: drv,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(AppPadding.p12),
      decoration: BoxDecoration(
        color: ColorManager.defaultWhite,
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_rounded, color: ColorManager.primary),
              SizedBox(width: AppWidth.s8),
              Expanded(
                child: CustomText(
                  text: widget.title,
                  textStyle: getSemiBoldStyle(
                    fontSize: AppFontSize.s14,
                    color: ColorManager.productNameColor,
                  ),
                ),
              ),
              if (widget.statusLabel != null && widget.statusLabel!.trim().isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppPadding.p10,
                    vertical: AppPadding.p4,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(AppRadius.r20),
                    border: Border.all(color: chipColor.withValues(alpha: 0.45)),
                  ),
                  child: CustomText(
                    text: widget.statusLabel!,
                    textStyle: getMediumStyle(
                      fontSize: AppFontSize.s11,
                      color: chipColor,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppHeight.s10),
          SizedBox(
            width: double.infinity,
            height: widget.height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.r12),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _fallbackCamera,
                  zoom: 15.2,
                ),
                markers: markers,
                polylines: _buildPolylines(),
                zoomControlsEnabled: false,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                onMapCreated: (controller) {
                  _controller = controller;
                  WidgetsBinding.instance.addPostFrameCallback((_) async {
                    if (!mounted) return;
                    await _moveCamera(initial: true);
                    if (mounted) {
                      setState(() => _didInitialCamera = true);
                    }
                  });
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
