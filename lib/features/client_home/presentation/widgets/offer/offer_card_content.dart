import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/features/offer/list_offer/domain/entities/offer_entity.dart';

/// Content overlay for offer card: merchant, title, description, discount badge.
class OfferCardContent extends StatelessWidget {
  const OfferCardContent({
    super.key,
    required this.offer,
    required this.discountText,
  });

  final OfferEntity offer;
  final String discountText;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppPadding.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (offer.merchant != null && offer.merchant!.name.isNotEmpty) ...[
            _line(offer.merchant!.name, AppFontSize.s11),
            SizedBox(height: AppHeight.s4),
          ],
          CustomText(
            text: offer.displayTitle,
            textStyle: getBoldStyle(
              fontSize: AppFontSize.s16,
              color: ColorManager.defaultWhite,
            ),
            maxLines: 2,
            textOverflow: TextOverflow.ellipsis,
          ),
          if (offer.displayDescription != null &&
              offer.displayDescription!.isNotEmpty) ...[
            SizedBox(height: AppHeight.s4),
            _line(offer.displayDescription!, AppFontSize.s12),
          ],
          SizedBox(height: AppHeight.s8),
          Row(
            children: [
              _discountChip(discountText),
              if (offer.products.isNotEmpty) ...[
                SizedBox(width: AppPadding.p8),
                CustomText(
                  text: AppTranslation.productsCountN(offer.products.length),
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s11,
                    color: ColorManager.defaultWhite.withOpacity(0.85),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String text, double fontSize) {
    return CustomText(
      text: text,
      textStyle: getRegularStyle(
        fontSize: fontSize,
        color: ColorManager.defaultWhite.withOpacity(0.9),
      ),
      maxLines: 1,
      textOverflow: TextOverflow.ellipsis,
    );
  }

  Widget _discountChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppPadding.p12,
        vertical: AppPadding.p4,
      ),
      decoration: BoxDecoration(
        color: ColorManager.defaultWhite.withOpacity(0.25),
        borderRadius: BorderRadius.circular(AppRadius.r8),
      ),
      child: CustomText(
        text: text,
        textStyle: getSemiBoldStyle(
          fontSize: AppFontSize.s12,
          color: ColorManager.defaultWhite,
        ),
      ),
    );
  }
}
