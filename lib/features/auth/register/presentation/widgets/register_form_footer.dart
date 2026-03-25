import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/navigation_extensions.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_button.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class RegisterFormFooter extends StatelessWidget {
  final VoidCallback onRegister;

  const RegisterFormFooter({super.key, required this.onRegister});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CustomButton(
          text: AppTranslation.register,
          onPressed: onRegister,
          color: ColorManager.primary,
        ),
        SizedBox(height: AppHeight.s24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomText(
              text: AppTranslation.alreadyHaveAccount,
              textStyle: getRegularStyle(
                fontSize: AppFontSize.s14,
                color: ColorManager.textColor,
              ),
            ),
            TextButton(
              onPressed: () => context.pushNamed(Routes.login),
              child: CustomText(
                text: AppTranslation.login,
                textStyle: getMediumStyle(
                  fontSize: AppFontSize.s14,
                  color: ColorManager.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
