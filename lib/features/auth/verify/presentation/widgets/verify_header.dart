import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class VerifyHeader extends StatelessWidget {
  final String email;

  const VerifyHeader({
    super.key,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Column(  
      children: [
        SizedBox(height: AppHeight.s50),
        CustomText(
          text: AppTranslation.verifyAccount,
          textStyle: getBoldStyle(
            fontSize: AppFontSize.s24,
            color: ColorManager.titlesColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppHeight.s8),
        CustomText(
          text: '${AppTranslation.otpSentSuccess}\n$email',
          textStyle: getRegularStyle(
            fontSize: AppFontSize.s14,
            color: ColorManager.textColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppHeight.s50),
      ],
    );
  }
}

