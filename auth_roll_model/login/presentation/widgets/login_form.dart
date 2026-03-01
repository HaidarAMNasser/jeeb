import 'package:flutter/material.dart';
import 'package:jeeb_admin/core/presentation/theme/values_manager.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_password_field.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_text_display.dart';
import 'package:jeeb_admin/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_admin/core/presentation/theme/font_manager.dart';
import 'package:jeeb_admin/core/presentation/localization/app_translation.dart';
import 'package:jeeb_admin/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_admin/core/presentation/routes/routes.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback onLogin;
  final bool isLoading;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.onLogin,
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
            title: AppTranslation.email,
            hintText: AppTranslation.enterEmail,
            controller: emailController,
          ),
          SizedBox(height: AppHeight.s24),
          CustomPasswordField(
            title: AppTranslation.password,
            hintText: AppTranslation.enterPassword,
            controller: passwordController,
          ),
          SizedBox(height: AppHeight.s16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                context.pushNamed(Routes.forgotPassword);
              },
              child: CustomTextDisplay(
                text: AppTranslation.forgotPassword,
                fontSize: AppFontSize.s14,
                color: ColorManager.primary,
              ),
            ),
          ),
          SizedBox(height: AppHeight.s32),
          CustomButton(
            text: AppTranslation.login,
            onPressed: onLogin,
            isLoading: isLoading,
            color: ColorManager.primary,
          ),
          SizedBox(height: AppHeight.s24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomTextDisplay(
                text: AppTranslation.dontHaveAccount,
                fontSize: AppFontSize.s14,
                color: ColorManager.textColor,
              ),
              TextButton(
                onPressed: () {
                  context.pushNamed(Routes.register);
                },
                child: CustomTextDisplay(
                  text: AppTranslation.register,
                  fontSize: AppFontSize.s14,
                  color: ColorManager.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

