import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: AppHeight.s50),
        CustomText(
          text: AppTranslation.appName,
          textStyle: TextStyle(
            fontSize: AppFontSize.s30,
            color: ColorManager.titlesColor,
            fontWeight: FontWeightManager.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppHeight.s8),
        CustomText(
          text: AppTranslation.welcome,
          textStyle: TextStyle(
            fontSize: AppFontSize.s16,
            color: ColorManager.textColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppHeight.s50),
      ],
    );
  }
}
