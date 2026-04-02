import 'package:dio/dio.dart';
import 'package:geocoding/geocoding.dart';

/// Result of reverse geocoding (country, city, street for UI).
class ResolvedAddress {
  final String? country;
  final String? city;
  final String? street;

  const ResolvedAddress({
    this.country,
    this.city,
    this.street,
  });
}

/// Single shared reverse-geocoding entry point (register, basket confirmation, etc.).
class AddressGeocoding {
  AddressGeocoding._();

  /// One row for UI: `street · city · country · lat, lng` (ellipsis applied by widget).
  static String formatDisplayLine({
    String? country,
    String? city,
    String? street,
    required String fallbackIfEmpty,
    required double latitude,
    required double longitude,
  }) {
    final coord =
        '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
    final parts = <String>[];
    for (final s in [street, city, country]) {
      final t = (s ?? '').trim();
      if (t.isNotEmpty) parts.add(t);
    }
    if (parts.isEmpty) return '$fallbackIfEmpty · $coord';
    return '${parts.join(' · ')} · $coord';
  }

  /// Reverse geocode: prefers OSM Nominatim so street/city match [flutter_map] tiles;
  /// falls back to platform [placemarkFromCoordinates] if the request fails.
  static Future<ResolvedAddress?> fromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    final osm = await _fromNominatim(latitude, longitude);
    if (osm != null) return osm;

    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isEmpty) return null;
      final p = _bestPlacemark(placemarks);
      return ResolvedAddress(
        country: p.country,
        city: _cityFromPlacemark(p),
        street: _streetFromPlacemark(p),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Public OSM reverse API; must send a descriptive User-Agent per usage policy.
Future<ResolvedAddress?> _fromNominatim(double latitude, double longitude) async {
  try {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          'User-Agent': 'JeebApp/1.0 (customer; https://jeeb2.com)',
          'Accept-Language': 'en,ar;q=0.9',
        },
      ),
    );
    final res = await dio.get<Map<String, dynamic>>(
      'https://nominatim.openstreetmap.org/reverse',
      queryParameters: <String, dynamic>{
        'lat': latitude,
        'lon': longitude,
        'format': 'json',
        'addressdetails': '1',
      },
    );
    final data = res.data;
    if (data == null) return null;
    final raw = data['address'];
    if (raw is! Map) return null;
    final addr = Map<String, dynamic>.from(raw);

    final street = _nominatimStreet(addr);
    final city = _nominatimCity(addr);
    final country = _sanitizeGeocoderDisplayString(
      addr['country']?.toString(),
    );

    if (street == null && city == null && country == null) return null;

    return ResolvedAddress(
      country: country,
      city: city,
      street: street,
    );
  } catch (_) {
    return null;
  }
}

String? _nominatimStreet(Map<String, dynamic> addr) {
  const roadKeys = <String>[
    'road',
    'pedestrian',
    'footway',
    'path',
    'residential',
    'living_street',
    'unclassified',
    'service',
  ];
  for (final key in roadKeys) {
    final v = addr[key]?.toString().trim();
    final part = _sanitizeGeocoderDisplayString(v);
    if (part == null) continue;
    final hn = addr['house_number']?.toString().trim();
    if (hn != null && hn.isNotEmpty) return '$hn $part';
    return part;
  }
  return null;
}

String? _nominatimCity(Map<String, dynamic> addr) {
  const keys = <String>[
    'city',
    'town',
    'village',
    'municipality',
    'state_district',
    'county',
    'suburb',
  ];
  for (final key in keys) {
    final s = _sanitizeGeocoderDisplayString(addr[key]?.toString());
    if (s != null) return s;
  }
  return null;
}

/// Prefer a [Placemark] with a real street line over POI-only [Placemark.name].
Placemark _bestPlacemark(List<Placemark> placemarks) {
  for (final p in placemarks) {
    if (_streetFromPlacemark(p) != null) return p;
  }
  return placemarks.first;
}

String? _cityFromPlacemark(Placemark p) {
  for (final candidate in <String?>[
        p.locality,
        p.subAdministrativeArea,
        p.administrativeArea,
      ]) {
    final sanitized = _sanitizeGeocoderDisplayString(candidate);
    if (sanitized != null) return sanitized;
  }
  return null;
}

String? _streetFromPlacemark(Placemark p) {
  // Omit [Placemark.name]: often a POI or district (e.g. "Al Jumhoriyh"), not the road.
  final candidates = <String?>[
    _joinStreetParts(p.thoroughfare, p.subThoroughfare),
    p.street,
    p.thoroughfare,
    p.subLocality,
  ];
  for (final candidate in candidates) {
    final sanitized = _sanitizeStreetCandidate(candidate);
    if (sanitized != null) return sanitized;
  }
  return null;
}

String? _joinStreetParts(String? thoroughfare, String? subThoroughfare) {
  final main = thoroughfare?.trim() ?? '';
  final sub = subThoroughfare?.trim() ?? '';
  if (main.isEmpty && sub.isEmpty) return null;
  if (main.isEmpty) return sub;
  if (sub.isEmpty) return main;
  return '$main $sub';
}

/// Drops empty strings and short alphanumeric blobs (e.g. Plus Code fragments).
String? _sanitizeGeocoderDisplayString(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return null;
  if (_looksLikePlaceCode(value)) return null;
  return value;
}

String? _sanitizeStreetCandidate(String? raw) =>
    _sanitizeGeocoderDisplayString(raw);

bool _looksLikePlaceCode(String value) {
  final compact = value.replaceAll(RegExp(r'[\s\-_]'), '');
  return compact.length <= 6 && RegExp(r'^[A-Z0-9]+$').hasMatch(compact);
}
