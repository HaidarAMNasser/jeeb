import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jeeb_app/core/presentation/theme/colors.dart';
import '../../../../core/presentation/theme/values_manager.dart';
import '../../../../core/presentation/localization/app_translation.dart';
import '../../../../core/presentation/widgets/custom_button.dart';
import '../../../../core/presentation/widgets/text_widget.dart';
import '../../../../core/presentation/theme/styles_manager.dart';
import '../../../../core/presentation/theme/font_manager.dart';
import '../bloc/onboarding_bloc.dart';
import 'onboarding_indicator.dart';

class OnboardingBottomSection extends StatelessWidget {
  final OnboardingLoaded state;
  final VoidCallback onGetStarted;
  final VoidCallback onNext;

  const OnboardingBottomSection({
    super.key,
    required this.state,
    required this.onGetStarted,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Terms and conditions text (only on first screen)
        // Reserve consistent space for all pages
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppPadding.p27,
            vertical: 32.h,
          ),
          child: state.currentPageIndex == 0
              ? CustomText(
                  text: AppTranslation.termsAndConditions,
                  textAlign: TextAlign.center,
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s14,
                    color: ColorManager.textColor.withOpacity(0.7),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        // Indicators
        OnboardingIndicator(
          currentIndex: state.currentPageIndex,
          totalPages: state.pages.length,
        ),
        SizedBox(height: AppHeight.s16),
        // Next/Get Started button
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppPadding.p27),
          child: Column(
            children: [
              // Always reserve space for notification button to keep layout consistent
              SizedBox(
                height: AppHeight.s56 + AppPadding.p16,
                child: state.currentPageIndex == 2
                    ? Padding(
                        padding: EdgeInsets.only(bottom: AppPadding.p16),
                        child: CustomButton(
                          text: AppTranslation.allowNotifications,
                          onPressed: () {
                            context.read<OnboardingBloc>().add(
                              const OnboardingRequestNotificationPermission(),
                            );
                          },
                        ),
                      )
                    : const SizedBox.shrink(),
              ),

              CustomButton(
                text: state.isLastPage
                    ? AppTranslation.getStarted
                    : AppTranslation.next,
                onPressed: state.isLastPage ? onGetStarted : onNext,
              ),
            ],
          ),
        ),
        SizedBox(height: AppHeight.s24),
      ],
    );
  }
}
