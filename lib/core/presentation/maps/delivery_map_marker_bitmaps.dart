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
  static const int _cacheGeneration = 2;
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
    _pickup = await _pin(
      fill: const Color(0xFF0F9D58),
      label: 'P',
    );
    return _pickup!;
  }

  static Future<BitmapDescriptor> dropoff() async {
    _bustCacheIfStale();
    if (_dropoff != null) return _dropoff!;
    _dropoff = await _pin(
      fill: const Color(0xFFEA4335),
      label: 'D',
    );
    return _dropoff!;
  }

  static Future<BitmapDescriptor> driver() async {
    _bustCacheIfStale();
    if (_driver != null) return _driver!;
    _driver = await _driverDot();
    return _driver!;
  }

  static Future<BitmapDescriptor> _pin({
    required Color fill,
    required String label,
  }) async {
    const size = 72.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const c = Offset(size / 2, size / 2);
    final fillPaint = Paint()..color = fill;
    canvas.drawCircle(c, 26, fillPaint);
    final ring = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(c, 26, ring);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2 - 1));
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> _driverDot() async {
    const size = 56.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const c = Offset(size / 2, size / 2);
    final outer = Paint()..color = Colors.white;
    canvas.drawCircle(c, 22, outer);
    final ring = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5;
    canvas.drawCircle(c, 18, ring);
    final inner = Paint()..color = const Color(0xFF4285F4);
    canvas.drawCircle(c, 9, inner);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }
}
