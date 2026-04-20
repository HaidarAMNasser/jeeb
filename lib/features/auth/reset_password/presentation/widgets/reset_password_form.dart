import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_password_field.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';

class ResetPasswordForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController otpController;
  final TextEditingController passwordController;
  final VoidCallback onReset;
  final bool isLoading;

  const ResetPasswordForm({
    super.key,
    required this.formKey,
    required this.otpController,
    required this.passwordController,
    required this.onReset,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppHeight.s50),
          CustomTextField(
            title: AppTranslation.otp,
            hintText: AppTranslation.enterOtp,
            controller: otpController,
          ),
          SizedBox(height: AppHeight.s24),
          CustomPasswordField(
            title: AppTranslation.newPassword,
            hintText: AppTranslation.enterPassword,
            controller: passwordController,
          ),
          SizedBox(height: AppHeight.s32),
          CustomButton(
            text: AppTranslation.resetPassword,
            onPressed: onReset,
            isLoading: isLoading,
            color: ColorManager.primary,
          ),
        ],
      ),
    );
  }
}

