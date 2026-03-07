import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/presentation/theme/colors_manager.dart';
import '../../../../core/presentation/theme/values_manager.dart';
import '../../../../core/presentation/theme/styles_manager.dart';
import '../../../../core/presentation/theme/font_manager.dart';
import '../../../../core/presentation/widgets/text_widget.dart';
import 'floating_icons.dart';

class OnboardingContent {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingContent({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class OnboardingContentWidget extends StatelessWidget {
  final OnboardingContent content;
  final int pageIndex;

  const OnboardingContentWidget({
    super.key,
    required this.content,
    required this.pageIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppPadding.p27,
        right: AppPadding.p27,
        bottom: 100.h,
      ),
      child: Stack(
        children: [
          // Floating icons background - more icons on second page
          Positioned.fill(
            child: FloatingIcons(
              pageIndex: pageIndex,
              iconCount: pageIndex == 1 ? 10 : 5, // More icons on second page
            ),
          ),
          // Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon container with gradient
              Container(
                width: AppWidth.s100 * 2,
                height: AppWidth.s100 * 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [content.color, content.color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.r40),
                  boxShadow: [
                    BoxShadow(
                      color: content.color.withOpacity(0.3),
                      blurRadius: AppSize.s30,
                      offset: Offset(0, AppHeight.s15),
                    ),
                  ],
                ),
                child: Icon(
                  content.icon,
                  size: AppSize.s100,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: AppHeight.s48),
              // Title
              CustomText(
                text: content.title,
                textAlign: TextAlign.center,
                textStyle: getBoldStyle(
                  fontSize: AppFontSize.s22,
                  color: ColorManager.textPrimary,
                ),
              ),
              SizedBox(height: AppHeight.s20),
              // Description
              CustomText(
                text: content.description,
                textAlign: TextAlign.center,
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s16,
                  color: ColorManager.textColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
