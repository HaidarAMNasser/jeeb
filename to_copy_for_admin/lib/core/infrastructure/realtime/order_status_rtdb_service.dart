import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:jeeb_app/core/infrastructure/realtime/route_history_point.dart';

/// Backend RTDB URL (see `backend/real_taime/Firebase_Realtime_Database.md`).
const String kOrderRtdbDatabaseUrl =
    'https://jeeb-f64a4-default-rtdb.europe-west1.firebasedatabase.app';

/// Listens to `/orders/{orderId}/status` for live status updates (replaces REST polling).
class OrderStatusRtdbService {
  OrderStatusRtdbService({FirebaseDatabase? database})
      : _db = database ??
            FirebaseDatabase.instanceFor(
              app: Firebase.app(),
              databaseURL: kOrderRtdbDatabaseUrl,
            );

  final FirebaseDatabase _db;

  /// Live `/orders/{orderId}/routeHistory` (driver path; backend appends via tracking API).
  Stream<List<RouteHistoryPoint>> watchOrderRouteHistory(String orderId) {
    final id = orderId.trim();
    if (id.isEmpty) {
      return const Stream.empty();
    }
    return _db.ref('orders/$id/routeHistory').onValue.map((event) {
      return RouteHistoryPoint.parseList(event.snapshot.value);
    });
  }

  /// Raw `status` string from RTDB (e.g. `PENDING`, `ON_THE_WAY`).
  Stream<String?> watchOrderStatusWire(String orderId) {
    final id = orderId.trim();
    if (id.isEmpty) {
      return const Stream.empty();
    }
    return _db.ref('orders/$id/status').onValue.map((event) {
      final v = event.snapshot.value;
      if (v == null) return null;
      if (v is String) return v;
      return v.toString();
    });
  }

  /// Delivery driver id for the order (`/orders/{orderId}/deliveryId`).
  Stream<int?> watchOrderDeliveryId(String orderId) {
    final id = orderId.trim();
    if (id.isEmpty) {
      return const Stream.empty();
    }
    return _db.ref('orders/$id/deliveryId').onValue.map((event) {
      final v = event.snapshot.value;
      if (v == null) return null;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v.trim());
      return int.tryParse(v.toString());
    });
  }

  /// Writes only `currentLat` / `currentLng` under `/drivers/{driverId}` (driver app; see Firebase doc).
  Future<void> updateDriverLocation(int driverId, double lat, double lng) async {
    if (driverId <= 0) return;
    try {
      await _db.ref('drivers/$driverId').update({
        'currentLat': lat,
        'currentLng': lng,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OrderStatusRtdbService.updateDriverLocation: $e');
      }
      rethrow;
    }
  }

  /// Writes only `isOnline` under `/drivers/{driverId}`.
  Future<void> updateDriverOnlineStatus(int driverId, bool isOnline) async {
    if (driverId <= 0) return;
    try {
      await _db.ref('drivers/$driverId').update({
        'isOnline': isOnline,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OrderStatusRtdbService.updateDriverOnlineStatus: $e');
      }
      rethrow;
    }
  }

  /// Live driver location from `/drivers/{driverId}`.
  Stream<DriverLiveLocation?> watchDriverLiveLocation(int driverId) {
    if (driverId <= 0) {
      return const Stream.empty();
    }
    return _db.ref('drivers/$driverId').onValue.map((event) {
      final v = event.snapshot.value;
      if (v is! Map) return null;
      final raw = Map<String, dynamic>.from(v);
      final lat = _asDouble(raw['currentLat']);
      final lng = _asDouble(raw['currentLng']);
      if (lat == null || lng == null) return null;
      final online = raw['isOnline'] == true;
      return DriverLiveLocation(latitude: lat, longitude: lng, isOnline: online);
    });
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return double.tryParse(v.toString());
  }
}

class DriverLiveLocation {
  const DriverLiveLocation({
    required this.latitude,
    required this.longitude,
    required this.isOnline,
  });

  final double latitude;
  final double longitude;
  final bool isOnline;
}
