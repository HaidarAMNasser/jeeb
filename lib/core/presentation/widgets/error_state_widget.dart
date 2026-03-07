import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';

class ErrorStateWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppPadding.p24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with gradient halo and shadow
            Container(
              width: 120.w,
              height: 120.h,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    ColorManager.primary.withOpacity(0.2),
                    ColorManager.primary.withOpacity(0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorManager.primary.withOpacity(0.3),
                    blurRadius: AppSize.s30,
                    spreadRadius: AppSize.s10,
                  ),
                  BoxShadow(
                    color: ColorManager.primary.withOpacity(0.1),
                    blurRadius: AppSize.s50,
                    spreadRadius: AppSize.s20,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer glow
                  Container(
                    width: 97.w,
                    height: 97.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          ColorManager.primary.withOpacity(0.4),
                          ColorManager.primary.withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  // Middle glow
                  Container(
                    width: 86.w ,
                    height: 86.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ColorManager.primary.withOpacity(0.3),
                          ColorManager.defaultYellow.withOpacity(0.2),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ColorManager.primary.withOpacity(0.5),
                          blurRadius: AppSize.s20,
                          spreadRadius: AppSize.s5,
                        ),
                      ],
                    ),
                  ),
                  // Icon container with gradient background
                  Container(
                    width: 76.w,
                    height: 76.h,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          ColorManager.primary,
                          ColorManager.defaultYellow,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ColorManager.primary.withOpacity(0.6),
                          blurRadius: AppSize.s12,
                          spreadRadius: AppSize.s3,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      size: AppSize.s50,
                      color: ColorManager.defaultWhite,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: AppHeight.s24),
            CustomText(
              text: message,
              textStyle: getSemiBoldStyle(
                fontSize: AppFontSize.s18,
                color: ColorManager.defaultWhite,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: AppHeight.s32),
              CustomButton(
                text: AppTranslation.retry,
                onPressed: () => onRetry!(),
                color: ColorManager.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

