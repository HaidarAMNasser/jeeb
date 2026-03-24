import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_date_select.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/offer/list_offer/domain/entities/offer_entity.dart';
import 'package:jeeb_app/features/product/list_product/presentation/widgets/product_list_item.dart';

class OfferDetailsContent extends StatelessWidget {
  final OfferEntity offer;

  const OfferDetailsContent({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final discountLabel =
        '${offer.discountValue} ${offer.discountType == 'PERCENTAGE' ? '%' : ''}';
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppPadding.p16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (offer.shortDescription != null) ...[
            CustomText(
              text: offer.shortDescription!,
              textStyle: getBoldStyle(
                fontSize: AppFontSize.s20,
                color: ColorManager.defaultWhite,
              ),
            ),
            SizedBox(height: AppHeight.s8),
          ],
          if (offer.longDescription != null) ...[
            CustomText(
              text: offer.longDescription!,
              textStyle: getRegularStyle(
                fontSize: AppFontSize.s14,
                color: ColorManager.textSecondary,
              ),
            ),
            SizedBox(height: AppHeight.s16),
          ],
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.p12,
              vertical: AppPadding.p8,
            ),
            decoration: BoxDecoration(
              color: ColorManager.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: CustomText(
              text: '${AppTranslation.offerDiscount}: $discountLabel',
              textStyle: getSemiBoldStyle(
                fontSize: AppFontSize.s14,
                color: ColorManager.primary,
              ),
            ),
          ),
          SizedBox(height: AppHeight.s12),
          Row(
            children: [
              Expanded(
                child: CustomDateSelect(
                  title: AppTranslation.offerStartDate,
                  initialValue: offer.startDate,
                  onDateSelected: (_) {},
                  isDisabled: true,
                ),
              ),
              SizedBox(width: AppWidth.s16),
              Expanded(
                child: CustomDateSelect(
                  title: AppTranslation.offerEndDate,
                  initialValue: offer.endDate,
                  onDateSelected: (_) {},
                  isDisabled: true,
                ),
              ),
            ],
          ),
          SizedBox(height: AppHeight.s16),
          CustomText(
            text: AppTranslation.offerProductsCount,
            textStyle: getBoldStyle(
              fontSize: AppFontSize.s16,
              color: ColorManager.defaultWhite,
            ),
          ),
          SizedBox(height: AppHeight.s8),
          ...offer.products.map((p) => ProductListItem(product: p)),
          SizedBox(height: AppHeight.s24),
        ],
      ),
    );
  }
}
