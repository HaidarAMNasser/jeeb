import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../../core/presentation/theme/values_manager.dart';
import '../../../../core/presentation/theme/styles_manager.dart';
import '../../../../core/presentation/theme/font_manager.dart';
import '../../../../core/presentation/widgets/text_widget.dart';

/// Widget that displays text with a curved/arched effect
/// and animates letters appearing one by one
class CurvedTextAnimation extends StatefulWidget {
  final String text;
  final TextStyle? textStyle;
  final double curveHeight;
  final Duration letterDelay;
  final Duration totalDuration;

  const CurvedTextAnimation({
    super.key,
    required this.text,
    this.textStyle,
    this.curveHeight = 20.0,
    this.letterDelay = const Duration(milliseconds: 150),
    this.totalDuration = const Duration(milliseconds: 2000),
  });

  @override
  State<CurvedTextAnimation> createState() => _CurvedTextAnimationState();
}

class _CurvedTextAnimationState extends State<CurvedTextAnimation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _fadeAnimations;
  late List<Animation<double>> _scaleAnimations;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _controllers = [];
    _fadeAnimations = [];
    _scaleAnimations = [];

    // Add initial delay before starting animations
    const initialDelay = Duration(milliseconds: 300);

    for (int i = 0; i < widget.text.length; i++) {
      final controller = AnimationController(
        duration: const Duration(milliseconds: 600),
        vsync: this,
      );

      final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );

      final scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.elasticOut,
        ),
      );

      _controllers.add(controller);
      _fadeAnimations.add(fadeAnimation);
      _scaleAnimations.add(scaleAnimation);

      // Stagger the animations with initial delay
      Future.delayed(
        initialDelay + Duration(milliseconds: i * widget.letterDelay.inMilliseconds),
        () {
          if (mounted) {
            controller.forward();
          }
        },
      );
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final letters = widget.text.split('');
    final textStyle = widget.textStyle ??
        getBoldStyle(
          fontSize: AppFontSize.s50,
          color: Colors.black87,
        );

    return SizedBox(
      height: (textStyle.fontSize ?? AppFontSize.s50) + widget.curveHeight + AppSize.s30,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(
          letters.length,
          (index) {
            // Calculate curve offset
            final progress = index / (letters.length - 1); // 0 to 1
            final angle = (progress - 0.5) * math.pi * 0.4; // -0.2π to 0.2π
            final yOffset = -math.sin(angle) * widget.curveHeight;

            return AnimatedBuilder(
              animation: _controllers[index],
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(0, yOffset * (1 - _scaleAnimations[index].value)),
                  child: Transform.scale(
                    scale: _scaleAnimations[index].value,
                    child: Opacity(
                      opacity: _fadeAnimations[index].value,
                      child: CustomText(
                        text: letters[index],
                        textStyle: textStyle,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

