import 'package:flutter/material.dart';
import 'package:jeeb_admin/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_admin/core/presentation/theme/font_manager.dart';
import 'package:jeeb_admin/core/presentation/theme/values_manager.dart';
import 'package:jeeb_admin/core/presentation/widgets/custom_text_display.dart';
import 'package:jeeb_admin/core/presentation/localization/app_translation.dart';

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
        CustomTextDisplay(
          text: AppTranslation.verifyAccount,
          fontSize: AppFontSize.s24,
          color: ColorManager.titlesColor,
          fontWeight: FontWeight.bold,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppHeight.s8),
        CustomTextDisplay(
          text: '${AppTranslation.otpSentSuccess}\n$email',
          fontSize: AppFontSize.s14,
          color: ColorManager.textColor,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppHeight.s50),
      ],
    );
  }
}

