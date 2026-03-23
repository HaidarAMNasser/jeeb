import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class ConfirmationPaymentNoticeCard extends StatelessWidget {
  final String totalText;

  const ConfirmationPaymentNoticeCard({super.key, required this.totalText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppPadding.p16),
      decoration: BoxDecoration(
        color: ColorManager.primary,
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: totalText,
            textStyle: getBoldStyle(
              fontSize: AppFontSize.s20,
              color: ColorManager.defaultWhite,
            ),
          ),
          SizedBox(height: AppHeight.s8),
          CustomText(
            text: AppTranslation.payOnDelivery,
            textStyle: getRegularStyle(
              fontSize: AppFontSize.s14,
              color: ColorManager.defaultWhite,
            ),
          ),
        ],
      ),
    );
  }
}
