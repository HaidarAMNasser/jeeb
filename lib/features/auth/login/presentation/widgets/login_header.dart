import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/gradient_text.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';


class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: AppHeight.s50),
        GradientText(
          text: AppTranslation.appName,
          textStyle: TextStyle(
            fontSize: AppFontSize.s30,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppHeight.s8),
        CustomText(
          text: AppTranslation.welcome,
          textStyle: getRegularStyle(
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
