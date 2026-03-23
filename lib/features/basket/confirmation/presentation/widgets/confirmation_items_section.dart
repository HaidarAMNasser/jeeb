import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/basket/confirmation/presentation/models/confirmation_item.dart';

class ConfirmationItemsSection extends StatelessWidget {
  final List<ConfirmationItem> items;
  final String merchantName;

  const ConfirmationItemsSection({
    super.key,
    required this.items,
    required this.merchantName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          text: AppTranslation.summary,
          textStyle: getSemiBoldStyle(
            fontSize: AppFontSize.s18,
            color: ColorManager.defaultWhite,
          ),
        ),
        SizedBox(height: AppHeight.s8),
        ...items.map(
          (item) => Container(
            margin: EdgeInsets.only(bottom: AppHeight.s8),
            padding: EdgeInsets.all(AppPadding.p12),
            decoration: BoxDecoration(
              color: ColorManager.defaultWhite,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: CustomText(
                    text: '${item.productName} x${item.quantity}',
                    textStyle: getSemiBoldStyle(
                      fontSize: AppFontSize.s14,
                      color: ColorManager.productNameColor,
                    ),
                  ),
                ),
                CustomText(
                  text: merchantName,
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s12,
                    color: ColorManager.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
