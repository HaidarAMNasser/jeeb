import 'package:flutter/material.dart';
import 'package:jeeb_admin/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_admin/core/presentation/theme/values_manager.dart';
import 'package:jeeb_admin/core/presentation/theme/font_manager.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_text_display.dart';
import 'package:jeeb_admin/core/presentation/localization/app_translation.dart';

class VerifyForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController otpController;
  final VoidCallback onVerify;
  final VoidCallback onResendOtp;
  final bool isLoading;

  const VerifyForm({
    super.key,
    required this.formKey,
    required this.otpController,
    required this.onVerify,
    required this.onResendOtp,
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
            isLoading: isLoading,
            color: ColorManager.primary,
          ),
          SizedBox(height: AppHeight.s16),
          TextButton(
            onPressed: onResendOtp,
            child: CustomTextDisplay(
              text: AppTranslation.resendOtp,
              fontSize: AppFontSize.s14,
              color: ColorManager.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

