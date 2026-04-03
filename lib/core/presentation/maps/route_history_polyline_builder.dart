import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/infrastructure/realtime/route_history_point.dart';

/// Builds multi-segment polylines with a warm→cool gradient (walked path from RTDB).
abstract final class RouteHistoryPolylineBuilder {
  RouteHistoryPolylineBuilder._();

  static List<LatLng> toLatLngs(List<RouteHistoryPoint> points) =>
      points.map((e) => LatLng(e.lat, e.lng)).toList();

  /// One [Polyline] per segment so colors can vary (Google Maps has no gradient stroke).
  static Set<Polyline> walkedPath({
    required String orderId,
    required List<LatLng> points,
    int width = 7,
  }) {
    if (points.length < 2) return {};
    const start = Color(0xFFE25706); // primary-adjacent
    const end = Color(0xFF00BFA5);
    final out = <Polyline>{};
    final n = points.length - 1;
    for (var i = 0; i < n; i++) {
      final t = n <= 1 ? 0.0 : i / (n - 1);
      final color = Color.lerp(start, end, t)!.withOpacity(0.92);
      out.add(
        Polyline(
          polylineId: PolylineId('walked_${orderId}_$i'),
          points: [points[i], points[i + 1]],
          color: color,
          width: width,
          zIndex: 3,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }
    return out;
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
