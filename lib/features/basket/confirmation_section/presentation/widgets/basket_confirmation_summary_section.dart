import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

/// Total + payment notice (cash on delivery).
class BasketConfirmationSummarySection extends StatelessWidget {
  final int totalMinorUnits;

  const BasketConfirmationSummarySection({
    super.key,
    required this.totalMinorUnits,
  });

  String get _totalLabel =>
      '${AppTranslation.total}: \$${(totalMinorUnits / 100).toStringAsFixed(2)}';

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
            text: _totalLabel,
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
