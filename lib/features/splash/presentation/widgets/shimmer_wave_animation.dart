import 'package:flutter/material.dart';

/// Shimmer wave animation widget that creates a wave effect
/// moving from bottom right to top left
class ShimmerWaveAnimation extends StatefulWidget {
  final Widget child;
  final Color primaryColor;
  final Color secondaryColor;
  final Duration duration;

  const ShimmerWaveAnimation({
    super.key,
    required this.child,
    required this.primaryColor,
    required this.secondaryColor,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<ShimmerWaveAnimation> createState() => _ShimmerWaveAnimationState();
}

class _ShimmerWaveAnimationState extends State<ShimmerWaveAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat();

    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.bottomRight,
              end: Alignment.topLeft,
              colors: [
                widget.primaryColor.withOpacity(0.3),
                widget.primaryColor.withOpacity(0.1),
                widget.secondaryColor.withOpacity(0.9),
                widget.primaryColor.withOpacity(0.1),
                widget.primaryColor.withOpacity(0.3),
              ],
              stops: const [0.0, 0.45, 0.5, 0.55, 1.0],
              transform: _SlidingGradientTransform(_animation.value),
            ).createShader(rect);
          },
          blendMode: BlendMode.srcATop,
          child: widget.child,
        );
      },
    );
  }
}

/// Gradient transform that moves the shimmer diagonally from bottom-right to top-left
class _SlidingGradientTransform extends GradientTransform {
  final double progress;

  const _SlidingGradientTransform(this.progress);

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    // Calculate diagonal movement
    // Progress 0: starts outside bottom-right (negative translation)
    // Progress 1: ends outside top-left (positive translation)
    final double diagonalDistance = (bounds.width + bounds.height) * 1.5;
    final double translateX = diagonalDistance * progress - diagonalDistance * 0.5;
    final double translateY = diagonalDistance * progress - diagonalDistance * 0.5;

    return Matrix4.translationValues(translateX, translateY, 0);
  }
}
