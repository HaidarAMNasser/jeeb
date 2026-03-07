import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? textStyle;
  final Gradient? gradient;
  final TextAlign? textAlign;

  const GradientText({
    super.key,
    required this.text,
    this.textStyle,
    this.gradient,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    final defaultGradient =
        gradient ??
        LinearGradient(
          colors: [ColorManager.defaultYellow, ColorManager.primary],
        );

    return ShaderMask(
      shaderCallback: (bounds) => defaultGradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(
        text,
        style:
            textStyle?.copyWith(color: Colors.white) ??
            const TextStyle(color: Colors.white),
        textAlign: textAlign,
      ),
    );
  }
}
