import 'package:firebase_auth/firebase_auth.dart';
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
    : _db =
          database ??
          FirebaseDatabase.instanceFor(
            app: Firebase.app(),
            databaseURL: kOrderRtdbDatabaseUrl,
          );

  final FirebaseDatabase _db;

  /// RTDB reads/writes use Firebase **anonymous** auth.
  /// A numeric [driverId] is not a valid JWT — do not pass it to [signInWithCustomToken].
  /// When the backend provides a real custom token for order-scoped rules, wire it here.
  Future<void> ensureFirebaseAuthForDriver(int driverId) async {
    await _signInAnonymousIfNeeded();
  }

  Future<void> _signInAnonymousIfNeeded() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OrderStatusRtdbService._signInAnonymousIfNeeded: $e');
      }
    }
  }

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

  /// Writes driver presence under `/drivers/{driverId}`.
  ///
  /// Includes [lastSeen] (ms) so the backend can drop stale drivers (>45s).
  Future<void> updateDriverPresence(
    int driverId, {
    required double lat,
    required double lng,
    required bool isOnline,
  }) async {
    if (driverId <= 0) return;
    await ensureFirebaseAuthForDriver(driverId);

    final path = 'drivers/$driverId';
    // Security rules only allow: currentLat, currentLng, isOnline.
    // Do NOT send id/createdAt — those are backend-only (permission-denied).
    final payload = {
      'currentLat': lat,
      'currentLng': lng,
      'isOnline': isOnline,
      'lastSeen': DateTime.now().millisecondsSinceEpoch,
    };

    if (kDebugMode) {
      debugPrint('┌─── RTDB WRITE ───────────────────────────');
      debugPrint('│ path:    /$path');
      debugPrint('│ method:  update (patch)');
      debugPrint(
        '│ authUid: ${FirebaseAuth.instance.currentUser?.uid}',
      );
      debugPrint('│ payload: $payload');
      debugPrint('└──────────────────────────────────────────');
    }

    try {
      await _db.ref(path).update(payload);
      if (kDebugMode) {
        debugPrint('✅ RTDB WRITE SUCCESS → /$path');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ RTDB WRITE FAILED → /$path — $e');
      }
      rethrow;
    }
  }

  /// Writes only `isOnline` under `/drivers/{driverId}` (disconnect / dispose).
  Future<void> updateDriverOnlineStatus(int driverId, bool isOnline) async {
    if (driverId <= 0) return;
    await ensureFirebaseAuthForDriver(driverId);
    try {
      await _db.ref('drivers/$driverId').update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OrderStatusRtdbService.updateDriverOnlineStatus: $e');
      }
      rethrow;
    }
  }

  /// When the Firebase connection drops, mark the driver offline automatically.
  Future<void> armDriverOfflineOnDisconnect(int driverId) async {
    if (driverId <= 0) return;
    await ensureFirebaseAuthForDriver(driverId);
    try {
      await _db.ref('drivers/$driverId').onDisconnect().update({
        'isOnline': false,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('OrderStatusRtdbService.armDriverOfflineOnDisconnect: $e');
      }
    }
  }

  Future<void> cancelDriverOfflineOnDisconnect(int driverId) async {
    if (driverId <= 0) return;
    try {
      await _db.ref('drivers/$driverId').onDisconnect().cancel();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'OrderStatusRtdbService.cancelDriverOfflineOnDisconnect: $e',
        );
      }
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
      return DriverLiveLocation(
        latitude: lat,
        longitude: lng,
        isOnline: online,
      );
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
