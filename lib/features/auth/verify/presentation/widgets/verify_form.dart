import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class VerifyForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController otpController;
  final VoidCallback onVerify;
  final VoidCallback onResendOtp;
  final VoidCallback onBackToLogin;
  final bool isLoading;

  const VerifyForm({
    super.key,
    required this.formKey,
    required this.otpController,
    required this.onVerify,
    required this.onResendOtp,
    required this.onBackToLogin,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            title: AppTranslation.otp,
            hintText: AppTranslation.enterOtp,
            controller: otpController,
          ),
          SizedBox(height: AppHeight.s24),
          CustomButton(
            text: AppTranslation.verifyAccount,
            onPressed: onVerify,
            color: ColorManager.primary,
          ),
          SizedBox(height: AppHeight.s16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: onResendOtp,
                child: CustomText(
                  text: AppTranslation.resendOtp,
                  textStyle: getMediumStyle(
                    fontSize: AppFontSize.s14,
                    color: ColorManager.primary,
                  ),
                ),
              ),

              TextButton(
                onPressed: onBackToLogin,
                child: CustomText(
                  text: AppTranslation.backToLogin,
                  textStyle: getMediumStyle(
                    fontSize: AppFontSize.s14,
                    color: ColorManager.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
