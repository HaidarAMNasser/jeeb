import 'package:equatable/equatable.dart';

/// Point from Firebase `/orders/{id}/routeHistory` (see Firebase_Realtime_Database.md).
class RouteHistoryPoint extends Equatable {
  final double lat;
  final double lng;
  final int timestampMs;

  const RouteHistoryPoint({
    required this.lat,
    required this.lng,
    required this.timestampMs,
  });

  static List<RouteHistoryPoint> parseList(dynamic value) {
    if (value is! List) return const [];
    final out = <RouteHistoryPoint>[];
    for (final e in value) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final lat = _asDouble(m['lat']);
      final lng = _asDouble(m['lng']);
      if (lat == null || lng == null) continue;
      final ts = m['timestamp'];
      int ms = 0;
      if (ts is int) {
        ms = ts;
      } else if (ts is double) {
        ms = ts.toInt();
      } else if (ts != null) {
        ms = int.tryParse(ts.toString()) ?? 0;
      }
      out.add(RouteHistoryPoint(lat: lat, lng: lng, timestampMs: ms));
    }
    return out;
  }

  static double? _asDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return double.tryParse(v.toString());
  }

  @override
  List<Object?> get props => [lat, lng, timestampMs];
}
