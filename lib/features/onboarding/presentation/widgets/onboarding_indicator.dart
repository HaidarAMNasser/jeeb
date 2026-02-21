import 'package:flutter/material.dart';
import '../../../../core/presentation/theme/colors_manager.dart';
import '../../../../core/presentation/theme/values_manager.dart';

class OnboardingIndicator extends StatelessWidget {
  final int currentIndex;
  final int totalPages;

  const OnboardingIndicator({
    super.key,
    required this.currentIndex,
    required this.totalPages,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: AppMargin.m4),
          width: currentIndex == index ? AppWidth.s32 : AppWidth.s8,
          height: AppHeight.s8,
          decoration: BoxDecoration(
            color: currentIndex == index
                ? ColorManager.primary
                : ColorManager.borderColor,
            borderRadius: BorderRadius.circular(AppRadius.r4),
          ),
        ),
      ),
    );
  }
}

