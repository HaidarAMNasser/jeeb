import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class OrderStatusProblemBanner extends StatelessWidget {
  const OrderStatusProblemBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppPadding.p16,
        AppPadding.p12,
        AppPadding.p16,
        0,
      ),
      child: Container(
        padding: EdgeInsets.all(AppPadding.p12),
        decoration: BoxDecoration(
          color: const Color(0xFFB84A4A).withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(
            color: const Color(0xFFE07070).withValues(alpha: 0.55),
          ),
        ),
        child: CustomText(
          text: AppTranslation.orderStatusProblemBanner,
          textStyle: getMediumStyle(
            fontSize: AppFontSize.s13,
            color: const Color(0xFFFFE4E4),
          ),
        ),
      ),
    );
  }
}
