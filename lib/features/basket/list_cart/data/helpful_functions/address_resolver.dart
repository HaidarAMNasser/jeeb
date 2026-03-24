import 'package:geocoding/geocoding.dart';

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

Future<ResolvedAddress?> resolveAddressFromCoordinates({
  required double latitude,
  required double longitude,
}) async {
  try {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) return null;
    final p = placemarks.first;
    return ResolvedAddress(
      country: p.country,
      city: resolveCityFromPlacemark(p),
      street: resolveStreetFromPlacemark(p),
    );
  } catch (_) {
    return null;
  }
}

String? resolveCityFromPlacemark(Placemark p) {
  if ((p.locality ?? '').isNotEmpty) return p.locality;
  if ((p.subAdministrativeArea ?? '').isNotEmpty) return p.subAdministrativeArea;
  return p.administrativeArea;
}

String? resolveStreetFromPlacemark(Placemark p) {
  final candidates = <String?>[
    joinStreetParts(p.thoroughfare, p.subThoroughfare),
    p.street,
    p.thoroughfare,
    p.subLocality,
    p.name,
  ];
  for (final candidate in candidates) {
    final sanitized = sanitizeStreetCandidate(candidate);
    if (sanitized != null) return sanitized;
  }
  return null;
}

String? joinStreetParts(String? thoroughfare, String? subThoroughfare) {
  final main = thoroughfare?.trim() ?? '';
  final sub = subThoroughfare?.trim() ?? '';
  if (main.isEmpty && sub.isEmpty) return null;
  if (main.isEmpty) return sub;
  if (sub.isEmpty) return main;
  return '$main $sub';
}

String? sanitizeStreetCandidate(String? raw) {
  final value = (raw ?? '').trim();
  if (value.isEmpty) return null;
  if (looksLikePlaceCode(value)) return null;
  return value;
}

bool looksLikePlaceCode(String value) {
  final compact = value.replaceAll(RegExp(r'[\s\-_]'), '');
  return compact.length <= 6 && RegExp(r'^[A-Z0-9]+$').hasMatch(compact);
}
