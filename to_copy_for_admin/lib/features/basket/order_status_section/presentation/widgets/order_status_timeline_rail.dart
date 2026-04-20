import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';

/// Wavy horizontal progress line with step dots (no caption).
class OrderStatusTimelineRail extends StatelessWidget {
  const OrderStatusTimelineRail({
    super.key,
    required this.stepCount,
    required this.activeIndex,
    this.height = 92,
  });

  final int stepCount;
  final int activeIndex;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (stepCount <= 0) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(
        painter: _HorizontalFullRailPainter(
          stepCount: stepCount,
          activeIndex: activeIndex.clamp(0, stepCount - 1),
        ),
      ),
    );
  }
}

class _HorizontalFullRailPainter extends CustomPainter {
  _HorizontalFullRailPainter({
    required this.stepCount,
    required this.activeIndex,
  });

  final int stepCount;
  final int activeIndex;

  static const double margin = 14;
  static const double _waveAmp = 24;
  static const double _waveFreq = 0.038;

  double _waveY(double x, double midY) =>
      midY + math.sin(x * _waveFreq) * _waveAmp;

  double _xAt(int i, double xMin, double xMax, int n) {
    if (n <= 1) return (xMin + xMax) / 2;
    return xMin + (xMax - xMin) * i / (n - 1);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final midY = size.height / 2;
    final xMin = margin;
    final xMax = w - margin;
    final n = stepCount;

    final greyPaint = Paint()
      ..color = const Color(0xFF6A6560)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.25
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final orangePaint = Paint()
      ..color = ColorManager.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final greyPath = Path();
    greyPath.moveTo(xMin, _waveY(xMin, midY));
    for (var x = xMin + 2; x <= xMax; x += 2) {
      greyPath.lineTo(x, _waveY(x, midY));
    }
    canvas.drawPath(greyPath, greyPaint);

    final xEnd = _xAt(activeIndex, xMin, xMax, n);
    if (xEnd > xMin + 2) {
      final orangePath = Path();
      orangePath.moveTo(xMin, _waveY(xMin, midY));
      for (var x = xMin + 2; x <= xEnd; x += 2) {
        orangePath.lineTo(x, _waveY(x, midY));
      }
      canvas.drawPath(orangePath, orangePaint);
    }

    final fillDone = Paint()..style = PaintingStyle.fill;
    final strokeTodo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (var i = 0; i < n; i++) {
      final xi = _xAt(i, xMin, xMax, n);
      final yi = _waveY(xi, midY);
      final c = Offset(xi, yi);

      if (i < activeIndex) {
        _drawReachedHalo(canvas, c, 9);
        fillDone.color = ColorManager.primary;
        canvas.drawCircle(c, 9, fillDone);
      } else if (i == activeIndex) {
        _drawReachedHalo(canvas, c, 12);
        fillDone.color = ColorManager.primary;
        canvas.drawCircle(c, 12, fillDone);
        _drawCheck(canvas, c);
      } else {
        strokeTodo.color = const Color(0xFF6A6560);
        canvas.drawCircle(c, 10, strokeTodo);
      }
    }
  }

  void _drawReachedHalo(Canvas canvas, Offset c, double coreRadius) {
    final primary = ColorManager.primary;
    const warmWhite = ColorManager.defaultYellow;

    canvas.drawCircle(
      c,
      coreRadius + 8,
      Paint()
        ..color = primary.withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );
    canvas.drawCircle(
      c,
      coreRadius + 4,
      Paint()
        ..color = primary.withValues(alpha: 0.42)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawCircle(
      c,
      coreRadius + 2,
      Paint()
        ..color = warmWhite.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
  }

  void _drawCheck(Canvas canvas, Offset c) {
    final p = Path()
      ..moveTo(c.dx - 5, c.dy + 1)
      ..lineTo(c.dx - 1.5, c.dy + 5)
      ..lineTo(c.dx + 6, c.dy - 4);
    canvas.drawPath(
      p,
      Paint()
        ..color = const Color(0xFFFFF5EC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _HorizontalFullRailPainter oldDelegate) {
    return oldDelegate.activeIndex != activeIndex ||
        oldDelegate.stepCount != stepCount;
  }
}
