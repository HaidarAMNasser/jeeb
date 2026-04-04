import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/infrastructure/realtime/route_history_point.dart';

/// Builds multi-segment polylines with a warm→cool gradient (walked path from RTDB).
abstract final class RouteHistoryPolylineBuilder {
  RouteHistoryPolylineBuilder._();

  static List<LatLng> toLatLngs(List<RouteHistoryPoint> points) =>
      points.map((e) => LatLng(e.lat, e.lng)).toList();

  /// Solid path from RTDB `routeHistory` (actual track) — above dashed planned route.
  static Set<Polyline> walkedPath({
    required String orderId,
    required List<LatLng> points,
    int width = 6,
  }) {
    if (points.length < 2) return {};
    return {
      Polyline(
        polylineId: PolylineId('walked_$orderId'),
        points: points,
        color: const Color(0xFFD32F2F).withOpacity(0.92),
        width: width,
        zIndex: 3,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
  }

  /// Planned road path (Directions API) — visually subordinate to walked path.
  static Polyline? plannedRoute({
    required String orderId,
    required List<LatLng> points,
  }) {
    if (points.length < 2) return null;
    return Polyline(
      polylineId: PolylineId('planned_$orderId'),
      points: points,
      color: ColorManager.titlesColor.withOpacity(0.35),
      width: 4,
      zIndex: 1,
      patterns: [PatternItem.dash(18), PatternItem.gap(10)],
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
  }
}
