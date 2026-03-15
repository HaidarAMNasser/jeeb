import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/localization/app_translation.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/offer/list_offer/domain/entities/offer_entity.dart';

class OfferListItem extends StatelessWidget {
  final OfferEntity offer;

  const OfferListItem({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    final discountLabel = offer.discountType == 'PERCENTAGE'
        ? '${offer.discountValue}%'
        : '${offer.discountValue}';

    return InkWell(
      onTap: () {
        AppRouter.navigateTo(
          context,
          Routes.offerDetails,
          arguments: {'offerId': offer.id},
        );
      },
      child: Card(
        color: ColorManager.defaultWhite,
        margin: EdgeInsets.only(bottom: AppMargin.m16),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
        child: Padding(
          padding: EdgeInsets.all(AppPadding.p16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CustomText(
                      text: offer.shortDescription ?? offer.id,
                      textStyle: getBoldStyle(
                        fontSize: AppFontSize.s18,
                        color: ColorManager.productNameColor,
                      ),
                      maxLines: 2,
                      textOverflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppPadding.p12,
                      vertical: AppPadding.p4,
                    ),
                    decoration: BoxDecoration(
                      color: ColorManager.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                    child: CustomText(
                      text: discountLabel,
                      textStyle: getSemiBoldStyle(
                        fontSize: AppFontSize.s12,
                        color: ColorManager.primary,
                      ),
                    ),
                  ),
                ],
              ),
              if (offer.longDescription != null) ...[
                SizedBox(height: AppHeight.s8),
                CustomText(
                  text: offer.longDescription!,
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s12,
                    color: ColorManager.descriptionColor,
                  ),
                  maxLines: 2,
                  textOverflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: AppHeight.s8),
              CustomText(
                text: '${AppTranslation.offerProductsCount}: ${offer.products.length}',
                textStyle: getRegularStyle(
                  fontSize: AppFontSize.s12,
                  color: ColorManager.descriptionColor,
                ),
              ),
              if (offer.startDate != null || offer.endDate != null) ...[
                SizedBox(height: AppHeight.s4),
                CustomText(
                  text: _formatDateRange(offer.startDate, offer.endDate),
                  textStyle: getRegularStyle(
                    fontSize: AppFontSize.s11,
                    color: ColorManager.descriptionColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    final s = start != null ? '${start.day}/${start.month}/${start.year}' : '—';
    final e = end != null ? '${end.day}/${end.month}/${end.year}' : '—';
    return '$s - $e';
  }
}
