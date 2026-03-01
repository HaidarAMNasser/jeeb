import 'package:flutter/material.dart';
import 'package:jeeb_admin/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_admin/core/presentation/theme/font_manager.dart';
import 'package:jeeb_admin/core/presentation/theme/values_manager.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_text_display.dart';
import 'package:jeeb_admin/core/presentation/localization/app_translation.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: AppHeight.s50),
        CustomTextDisplay(
          text: AppTranslation.appName,
          fontSize: AppFontSize.s30,
          color: ColorManager.titlesColor,
          fontWeight: FontWeight.bold,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppHeight.s8),
        CustomTextDisplay(
          text: AppTranslation.welcome,
          fontSize: AppFontSize.s16,
          color: ColorManager.textColor,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppHeight.s50),
      ],
    );
  }
}

