import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/basket/list_cart/presentation/bloc/list_cart_bloc.dart';

class BasketSummaryCard extends StatelessWidget {
  final List<CartDraftItem> items;
  final int total;
  final String merchantName;
  final String Function(int) priceFormatter;

  const BasketSummaryCard({
    super.key,
    required this.items,
    required this.total,
    required this.merchantName,
    required this.priceFormatter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppPadding.p16),
      decoration: BoxDecoration(
        color: ColorManager.lightPrimary,
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            text: '${AppTranslation.total}: SYP ${priceFormatter(total)}',
            textStyle: getBoldStyle(
              fontSize: AppFontSize.s20,
              color: ColorManager.primary,
            ),
          ),
          SizedBox(height: AppHeight.s8),
          CustomText(
            text: AppTranslation.summary,
            textStyle: getSemiBoldStyle(
              fontSize: AppFontSize.s16,
              color: ColorManager.textDarkColor,
            ),
          ),
          SizedBox(height: AppHeight.s8),
          ...items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: AppHeight.s4),
              child: Row(
                children: [
                  Expanded(
                    child: CustomText(
                      text: '${item.productName} x${item.quantity}',
                      textStyle: getRegularStyle(
                        fontSize: AppFontSize.s13,
                        color: ColorManager.textDarkColor,
                      ),
                    ),
                  ),
                  if (merchantName.isNotEmpty)
                    CustomText(
                      text: merchantName,
                      textStyle: getRegularStyle(
                        fontSize: AppFontSize.s12,
                        color: ColorManager.textDarkColor.withOpacity(0.9),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
