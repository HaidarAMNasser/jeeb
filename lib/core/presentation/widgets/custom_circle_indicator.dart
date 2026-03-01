import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';

class CustomCircleIndicator extends StatelessWidget {
  final Color? color;
  final double? strokeWidth;

  const CustomCircleIndicator({
    super.key,
    this.color,
    this.strokeWidth,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CircularProgressIndicator(
        color: color ?? ColorManager.primary,
        strokeWidth: strokeWidth ?? 4.0,
      ),
    );
  }
}

