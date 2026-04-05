import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Distinct map pins (restaurant / drop-off / driver) — not default teardrop hues.
abstract final class DeliveryMapMarkerBitmaps {
  DeliveryMapMarkerBitmaps._();

  static BitmapDescriptor? _pickup;
  static BitmapDescriptor? _dropoff;
  static BitmapDescriptor? _driver;

  static Future<BitmapDescriptor> pickup() async {
    if (_pickup != null) return _pickup!;
    _pickup = await _pin(
      fill: const Color(0xFF0F9D58),
      label: 'P',
    );
    return _pickup!;
  }

  static Future<BitmapDescriptor> dropoff() async {
    if (_dropoff != null) return _dropoff!;
    _dropoff = await _pin(
      fill: const Color(0xFFEA4335),
      label: 'D',
    );
    return _dropoff!;
  }

  static Future<BitmapDescriptor> driver() async {
    if (_driver != null) return _driver!;
    _driver = await _driverDot();
    return _driver!;
  }

  static Future<BitmapDescriptor> _pin({
    required Color fill,
    required String label,
  }) async {
    const size = 112.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const c = Offset(size / 2, size / 2);
    final fillPaint = Paint()..color = fill;
    canvas.drawCircle(c, 40, fillPaint);
    final ring = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(c, 40, ring);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 44,
          fontWeight: FontWeight.w800,
          letterSpacing: -1,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2 - 2));
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
    }
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  static Future<BitmapDescriptor> _driverDot() async {
    const size = 96.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const c = Offset(size / 2, size / 2);
    final outer = Paint()..color = Colors.white;
    canvas.drawCircle(c, 36, outer);
    final ring = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(c, 30, ring);
    final inner = Paint()..color = const Color(0xFF4285F4);
    canvas.drawCircle(c, 14, inner);
    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }
}
