import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Color? color;
  final double? width;
  final double? height;
  final double? borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.color,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height ?? AppHeight.s56,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: color ?? ColorManager.primary,
                  width: AppSize.s2_5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.r16),
                ),
              ),
              child: _buildChild(),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? ColorManager.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadius ?? AppRadius.r16),
                ),
                elevation: AppSize.s5,
                shadowColor: (color ?? ColorManager.primary).withOpacity(0.4),
              ),
              child: _buildChild(),
            ),
    );
  }

  Widget _buildChild() {
    if (isLoading) {
      return SizedBox(
        width: AppSize.s24,
        height: AppSize.s24,
        child: CircularProgressIndicator(
          color: isOutlined
              ? (color ?? ColorManager.primary)
              : Colors.white,
          strokeWidth: AppSize.s2_5,
        ),
      );
    }
    return CustomText(
      text: text,
      textStyle: getBlackStyle(
        fontSize: AppFontSize.s18,
        color: isOutlined
            ? (color ?? ColorManager.primary)
            : Colors.white,
      ),
    );
  }
}
