import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/infrastructure/realtime/route_history_point.dart';

/// Polylines for Directions legs (dashed) + RTDB walked path (segmented colors).
abstract final class RouteHistoryPolylineBuilder {
  RouteHistoryPolylineBuilder._();

  static List<LatLng> toLatLngs(List<RouteHistoryPoint> points) =>
      points.map((e) => LatLng(e.lat, e.lng)).toList();

  /// Actual path from RTDB `routeHistory` — segmented green→red (reads with traffic layer on map).
  static Set<Polyline> walkedPath({
    required String orderId,
    required List<LatLng> points,
    int width = 6,
  }) {
    if (points.length < 2) return {};
    final n = points.length;
    const maxSeg = 12;
    final segCount = math.min(maxSeg, math.max(1, (n / 3).ceil()));
    final out = <Polyline>{};
    for (var i = 0; i < segCount; i++) {
      final start = (i * (n - 1) / segCount).floor();
      var endIdx = ((i + 1) * (n - 1) / segCount).ceil();
      if (i == segCount - 1) endIdx = n - 1;
      endIdx = endIdx.clamp(0, n - 1);
      if (endIdx <= start) continue;
      final seg = points.sublist(start, endIdx + 1);
      if (seg.length < 2) continue;
      final t = segCount <= 1 ? 0.0 : i / (segCount - 1);
      final color = Color.lerp(
        const Color(0xFF34A853),
        const Color(0xFFEA4335),
        t,
      )!.withValues(alpha: 0.92);
      out.add(
        Polyline(
          polylineId: PolylineId('walked_${orderId}_$i'),
          points: seg,
          color: color,
          width: width,
          zIndex: 3,
          jointType: JointType.round,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
        ),
      );
    }
    if (out.isEmpty) {
      out.add(
        Polyline(
          polylineId: PolylineId('walked_$orderId'),
          points: points,
          color: const Color(0xFF4285F4).withValues(alpha: 0.92),
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

  /// Driver → restaurant (Directions API), dashed blue.
  static Polyline? plannedPickupLeg({
    required String orderId,
    required List<LatLng> points,
  }) {
    if (points.length < 2) return null;
    return Polyline(
      polylineId: PolylineId('planned_pickup_$orderId'),
      points: points,
      color: const Color(0xFF1A73E8).withValues(alpha: 0.88),
      width: 5,
      zIndex: 2,
      patterns: [PatternItem.dash(16), PatternItem.gap(10)],
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
  }

  /// Restaurant → drop-off (Directions API), dashed amber.
  static Polyline? plannedDropoffLeg({
    required String orderId,
    required List<LatLng> points,
  }) {
    if (points.length < 2) return null;
    return Polyline(
      polylineId: PolylineId('planned_dropoff_$orderId'),
      points: points,
      color: const Color(0xFFFBBC04).withValues(alpha: 0.92),
      width: 5,
      zIndex: 2,
      patterns: [PatternItem.dash(16), PatternItem.gap(10)],
      jointType: JointType.round,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );
  }
}
