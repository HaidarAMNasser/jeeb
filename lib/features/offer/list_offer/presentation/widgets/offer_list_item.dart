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
import 'package:jeeb_app/features/product/list_product/domain/entities/product_image_entity.dart';
import 'package:jeeb_app/features/product/list_product/presentation/widgets/product_item_image_carousel.dart';

class OfferListItem extends StatelessWidget {
  final OfferEntity offer;
  final bool enableSmallDesign;

  const OfferListItem({
    super.key,
    required this.offer,
    this.enableSmallDesign = true,
  });

  /// All product images from the offer (for image slider).
  List<ProductImageEntity> get _images {
    return offer.products.expand((p) => p.images).toList();
  }

  @override
  Widget build(BuildContext context) {
    final images = _images;
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductItemImageCarousel(
            key: ValueKey('offer_${offer.id}_${images.length}'),
            images: images,
            enableSmallDesign: enableSmallDesign,
          ),
          Container(
            margin: EdgeInsets.only(bottom: AppMargin.m16),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: ColorManager.defaultWhite,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.r16),
                bottomRight: Radius.circular(AppRadius.r16),
              ),
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
                          text: offer.displayTitle,
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
                          borderRadius:
                              BorderRadius.circular(AppRadius.r12),
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
                  if (offer.displayDescription != null &&
                      offer.displayDescription!.isNotEmpty) ...[
                    SizedBox(height: AppHeight.s8),
                    CustomText(
                      text: offer.displayDescription!,
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
        ],
      ),
    );
  }

  String _formatDateRange(DateTime? start, DateTime? end) {
    final s = start != null
        ? '${start.day}/${start.month}/${start.year}'
        : '—';
    final e =
        end != null ? '${end.day}/${end.month}/${end.year}' : '—';
    return '$s - $e';
  }
}
