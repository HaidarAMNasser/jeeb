import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_text_field.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';

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
            label: AppTranslation.email,
            hint: AppTranslation.enterEmail,
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: AppHeight.s24),
          CustomTextField(
            label: AppTranslation.password,
            hint: AppTranslation.enterPassword,
            controller: passwordController,
            obscureText: true,
          ),
          SizedBox(height: AppHeight.s16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                context.pushNamed(Routes.forgotPassword);
              },
              child: CustomText(
                text: AppTranslation.forgotPassword,
                textStyle: TextStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.primary,
                ),
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
              CustomText(
                text: AppTranslation.dontHaveAccount,
                textStyle: TextStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.textColor,
                ),
              ),
              TextButton(
                onPressed: () {
                  context.pushNamed(Routes.register);
                },
                child: CustomText(
                  text: AppTranslation.register,
                  textStyle: TextStyle(
                    fontSize: AppFontSize.s14,
                    color: ColorManager.primary,
                    fontWeight: FontWeightManager.semiBold,
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
