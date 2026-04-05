import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:jeeb_app/core/config/google_api_config.dart';

/// Fetches a driving route polyline from [Google Directions API](https://developers.google.com/maps/documentation/directions/overview).
class GoogleDirectionsService {
  GoogleDirectionsService._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ),
  );

  /// Decoded path points for the first route, or null if unavailable / error.
  /// [trafficAware] adds departure time + traffic model so routes follow current traffic.
  static Future<List<LatLng>?> getDrivingPolyline({
    required double originLat,
    required double originLng,
    required double destinationLat,
    required double destinationLng,
    bool trafficAware = true,
  }) async {
    final key = GoogleApiConfig.directionsApiKey.trim();
    if (key.isEmpty) return null;

    Future<List<LatLng>?> fetch({required bool withTraffic}) async {
      final queryParameters = <String, dynamic>{
        'origin': '$originLat,$originLng',
        'destination': '$destinationLat,$destinationLng',
        'mode': 'driving',
        'key': key,
      };
      if (withTraffic) {
        queryParameters['departure_time'] =
            DateTime.now().millisecondsSinceEpoch ~/ 1000;
        queryParameters['traffic_model'] = 'best_guess';
      }

      final res = await _dio.get<Map<String, dynamic>>(
        'https://maps.googleapis.com/maps/api/directions/json',
        queryParameters: queryParameters,
      );
      final data = res.data;
      if (data == null) return null;
      if (data['status'] != 'OK') return null;
      final routes = data['routes'];
      if (routes is! List || routes.isEmpty) return null;
      final first = routes.first;
      if (first is! Map<String, dynamic>) return null;
      final overview = first['overview_polyline'];
      if (overview is! Map<String, dynamic>) return null;
      final encoded = overview['points'] as String?;
      if (encoded == null || encoded.isEmpty) return null;

      final decoded = decodePolyline(encoded);
      return decoded
          .map(
            (e) => LatLng(
              (e[0]).toDouble(),
              (e[1]).toDouble(),
            ),
          )
          .toList(growable: false);
    }

    try {
      if (trafficAware) {
        final withTraffic = await fetch(withTraffic: true);
        if (withTraffic != null) return withTraffic;
        return await fetch(withTraffic: false);
      }
      return await fetch(withTraffic: false);
    } catch (_) {
      return null;
    }
  }
}
