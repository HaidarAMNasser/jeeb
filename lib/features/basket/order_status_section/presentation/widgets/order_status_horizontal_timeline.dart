import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Horizontal wavy rail: grey track + orange progress + all step **dots** on the line.
/// Below the rail, only the **current** icon + title — **aligned under that dot** on the wave
/// (not centered on screen). Smaller type. Repaints when [activeIndex] changes.
class OrderStatusHorizontalTimeline extends StatelessWidget {
  const OrderStatusHorizontalTimeline({
    super.key,
    required this.labels,
    required this.activeIndex,
  });

  final List<String> labels;
  final int activeIndex;

  static const List<IconData> _icons = [
    Icons.receipt_long_rounded,
    Icons.verified_outlined,
    Icons.restaurant_rounded,
    Icons.takeout_dining_rounded,
    Icons.two_wheeler_rounded,
    Icons.pedal_bike_rounded,
    Icons.home_outlined,
  ];

  static const double _railHeight = 72;

  /// Same x as [_HorizontalFullRailPainter] dot positions (must stay in sync).
  static double _dotCenterX(double width, int index, int count) {
    const margin = _HorizontalFullRailPainter.margin;
    final xMin = margin;
    final xMax = width - margin;
    if (count <= 1) return (xMin + xMax) / 2;
    return xMin + (xMax - xMin) * index / (count - 1);
  }

  @override
  Widget build(BuildContext context) {
    final n = labels.length;
    if (n == 0) return const SizedBox.shrink();
    final idx = activeIndex.clamp(0, n - 1);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppPadding.p12,
        AppPadding.p12,
        AppPadding.p12,
        AppPadding.p8,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final dotX = _dotCenterX(w, idx, n);
            final blockW = math.min(132.0, w * 0.44);
            final maxLeft = math.max(0.0, w - blockW);
            final left = (dotX - blockW / 2).clamp(0.0, maxLeft).toDouble();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: _railHeight,
                  child: CustomPaint(
                    painter: _HorizontalFullRailPainter(
                      stepCount: n,
                      activeIndex: idx,
                    ),
                  ),
                ),
                SizedBox(height: AppHeight.s8),
                SizedBox(
                  width: w,
                  height: 48,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: left,
                        width: blockW,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              idx < _icons.length
                                  ? _icons[idx]
                                  : Icons.flag_outlined,
                              size: 18,
                              color: ColorManager.primary,
                            ),
                            SizedBox(width: AppPadding.p6),
                            Expanded(
                              child: CustomText(
                                text: labels[idx],
                                textStyle: getSemiBoldStyle(
                                  fontSize: AppFontSize.s12,
                                  color: const Color(0xFFFFF5EC),
                                ),
                                maxLines: 3,
                                textAlign: TextAlign.start,
                                textOverflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
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
  static const double _waveAmp = 11;
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
      ..strokeWidth = 2.75
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
        fillDone.color = ColorManager.primary;
        canvas.drawCircle(c, 8, fillDone);
      } else if (i == activeIndex) {
        fillDone.color = ColorManager.primary;
        canvas.drawCircle(c, 11, fillDone);
        _drawCheck(canvas, c);
      } else {
        strokeTodo.color = const Color(0xFF6A6560);
        canvas.drawCircle(c, 9, strokeTodo);
      }
    }
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
        ..strokeWidth = 2
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
