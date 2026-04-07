import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jeeb_app/core/infrastructure/realtime/route_history_point.dart';

/// Polylines for directions legs (dashed) + RTDB walked path.
abstract final class RouteHistoryPolylineBuilder {
  RouteHistoryPolylineBuilder._();

  static List<LatLng> toLatLngs(List<RouteHistoryPoint> points) =>
      points.map((e) => LatLng(e.lat, e.lng)).toList();

  /// Actual walked path from RTDB `routeHistory` as a single solid red line.
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
        color: const Color(0xFFEA4335).withValues(alpha: 0.94),
        width: width,
        zIndex: 3,
        jointType: JointType.round,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
      ),
    };
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
