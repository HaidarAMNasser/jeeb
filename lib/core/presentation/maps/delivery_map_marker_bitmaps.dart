import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Distinct map pins (restaurant / drop-off / driver) — not default teardrop hues.
abstract final class DeliveryMapMarkerBitmaps {
  DeliveryMapMarkerBitmaps._();

  static BitmapDescriptor? _pickup;
  static BitmapDescriptor? _dropoff;
  static BitmapDescriptor? _driver;

  /// Bump when pin artwork changes so cached [BitmapDescriptor]s are regenerated.
  static const int _cacheGeneration = 4;
  static int? _loadedGeneration;

  static void _bustCacheIfStale() {
    if (_loadedGeneration != _cacheGeneration) {
      _pickup = null;
      _dropoff = null;
      _driver = null;
      _loadedGeneration = _cacheGeneration;
    }
  }

  static Future<BitmapDescriptor> pickup() async {
    _bustCacheIfStale();
    if (_pickup != null) return _pickup!;
    _pickup = await _iconPin(
      fill: const Color(0xFFFF7043),
      icon: Icons.restaurant_rounded,
    );
    return _pickup!;
  }

  static Future<BitmapDescriptor> dropoff() async {
    _bustCacheIfStale();
    if (_dropoff != null) return _dropoff!;
    _dropoff = await _iconPin(
      fill: const Color(0xFF34A853),
      icon: Icons.flag_rounded,
    );
    return _dropoff!;
  }

  static Future<BitmapDescriptor> driver() async {
    _bustCacheIfStale();
    if (_driver != null) return _driver!;
    _driver = await _iconPin(
      fill: const Color(0xFF1A73E8),
      icon: Icons.delivery_dining_rounded,
    );
    return _driver!;
  }

  static Future<BitmapDescriptor> _iconPin({
    required Color fill,
    required IconData icon,
  }) async {
    const size = 84.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const c = Offset(size / 2, 34);
    final fillPaint = Paint()..color = fill;
    final shadowPaint = Paint()..color = Colors.black.withValues(alpha: 0.18);
    canvas.drawCircle(const Offset(size / 2, 38), 25, shadowPaint);
    canvas.drawCircle(c, 24, fillPaint);
    final ring = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(c, 24, ring);
    final pointerPath = Path()
      ..moveTo(c.dx, 76)
      ..lineTo(c.dx - 10, 52)
      ..lineTo(c.dx + 10, 52)
      ..close();
    canvas.drawPath(pointerPath, fillPaint);
    canvas.drawPath(pointerPath, ring);
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }
}
