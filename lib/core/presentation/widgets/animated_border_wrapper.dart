import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors.dart';

/// A widget that wraps a child with an animated gradient border when loading
class AnimatedBorderWrapper extends StatefulWidget {
  final Widget child;
  final double borderWidth;
  final double borderRadius;
  final bool isLoading;

  const AnimatedBorderWrapper({
    super.key,
    required this.child,
    this.borderWidth = 1.3,
    this.borderRadius = 30.0,
    this.isLoading = true,
  });

  @override
  State<AnimatedBorderWrapper> createState() => _AnimatedBorderWrapperState();
}

class _AnimatedBorderWrapperState extends State<AnimatedBorderWrapper>
    with TickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    _updateController();
  }

  void _updateController() {
    if (widget.isLoading) {
      if (_controller == null) {
        _controller = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 2),
        )..repeat();
      }
    } else {
      _controller?.dispose();
      _controller = null;
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedBorderWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoading != widget.isLoading) {
      setState(() {
        _updateController();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading || _controller == null) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _controller!,
      builder: (_, __) {
        return CustomPaint(
          painter: _AnimatedGradientBorderPainter(
            animationValue: _controller!.value,
            borderRadius: widget.borderRadius,
            strokeWidth: widget.borderWidth,
          ),
          child: Container(
            padding: EdgeInsets.all(widget.borderWidth),
            child: widget.child,
          ),
        );
      },
    );
  }
}

class _AnimatedGradientBorderPainter extends CustomPainter {
  final double animationValue;
  final double borderRadius;
  final double strokeWidth;

  _AnimatedGradientBorderPainter({
    required this.animationValue,
    required this.borderRadius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final gradient = SweepGradient(
      startAngle: 0.0,
      endAngle: 6.28,
      tileMode: TileMode.repeated,
      transform: GradientRotation(2 * 3.14 * animationValue),
      colors: const [
        Colors.transparent,
        ColorManager.primary,
        ColorManager.primary,
        Colors.transparent,
      ],
      stops: const [0.0, 0.4, 0.6, 1.0],
    );

    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw border - deflate to ensure it's drawn inside canvas bounds
    final rRect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(borderRadius),
    );

    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedGradientBorderPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
