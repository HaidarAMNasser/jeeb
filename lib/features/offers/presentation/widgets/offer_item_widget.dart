import 'package:flutter/material.dart';
import '../../../../core/presentation/theme/colors_manager.dart';
import '../../../../core/presentation/theme/font_manager.dart';
import '../../../../core/presentation/theme/styles_manager.dart';
import '../../../../core/presentation/theme/values_manager.dart';
import '../../domain/entities/offer_entity.dart';

class OfferItemWidget extends StatelessWidget {
  final OfferEntity offer;

  const OfferItemWidget({super.key, required this.offer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: AppHeight.s16),
      decoration: BoxDecoration(
        color: ColorManager.surface,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with discount badge
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppPadding.p16),
            decoration: BoxDecoration(
              color: ColorManager.primary.withOpacity(0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.r12),
                topRight: Radius.circular(AppRadius.r12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.name,
                        style: getBoldStyle(
                          fontSize: AppFontSize.s16,
                          color: ColorManager.primary,
                        ),
                      ),
                      SizedBox(height: AppHeight.s4),
                      Text(
                        offer.merchant.restaurantName,
                        style: getRegularStyle(
                          fontSize: AppFontSize.s12,
                          color: ColorManager.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppPadding.p12,
                    vertical: AppPadding.p4,
                  ),
                  decoration: BoxDecoration(
                    color: ColorManager.primary,
                    borderRadius: BorderRadius.circular(AppRadius.r8),
                  ),
                  child: Text(
                    '${offer.discountType.name == 'PERCENTAGE' ? '${offer.discountValue.toInt()}%' : '${offer.discountValue.toInt()} LBP'}',
                    style: getBoldStyle(
                      fontSize: AppFontSize.s12,
                      color: ColorManager.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Description and products
          Padding(
            padding: EdgeInsets.all(AppPadding.p16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offer.description,
                  style: getRegularStyle(
                    fontSize: AppFontSize.s14,
                    color: ColorManager.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppHeight.s12),

                // Products list
                if (offer.products.isNotEmpty) ...[
                  Text(
                    'Products:',
                    style: getMediumStyle(
                      fontSize: AppFontSize.s12,
                      color: ColorManager.primary,
                    ),
                  ),
                  SizedBox(height: AppHeight.s8),
                  ...offer.products
                      .take(3)
                      .map(
                        (product) => Padding(
                          padding: EdgeInsets.only(bottom: AppHeight.s4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  product.name,
                                  style: getRegularStyle(
                                    fontSize: AppFontSize.s12,
                                    color: ColorManager.textSecondary,
                                  ),
                                ),
                              ),
                              if (product.offerPrice != null) ...[
                                Text(
                                  '${product.offerPrice!.toInt()} LBP',
                                  style: getBoldStyle(
                                    fontSize: AppFontSize.s12,
                                    color: ColorManager.primary,
                                  ),
                                ),
                                SizedBox(width: AppWidth.s8),
                                Text(
                                  '${product.price.toInt()} LBP',
                                  style:
                                      getRegularStyle(
                                        fontSize: AppFontSize.s10,
                                        color: ColorManager.textSecondary,
                                      ).copyWith(
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                ),
                              ] else ...[
                                Text(
                                  '${product.price.toInt()} LBP',
                                  style: getBoldStyle(
                                    fontSize: AppFontSize.s12,
                                    color: ColorManager.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                  if (offer.products.length > 3)
                    Text(
                      '+${offer.products.length - 3} more',
                      style: getRegularStyle(
                        fontSize: AppFontSize.s10,
                        color: ColorManager.textSecondary,
                      ),
                    ),
                ],
              ],
            ),
          ),

          // Footer with dates
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppPadding.p16,
              0,
              AppPadding.p16,
              AppPadding.p16,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: ColorManager.textSecondary,
                ),
                SizedBox(width: AppWidth.s4),
                Text(
                  '${_formatDate(offer.startDate)} - ${_formatDate(offer.endDate)}',
                  style: getRegularStyle(
                    fontSize: AppFontSize.s10,
                    color: ColorManager.textSecondary,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppPadding.p8,
                    vertical: AppHeight.s2_5,
                  ),
                  decoration: BoxDecoration(
                    color: offer.isActive
                        ? ColorManager.success
                        : ColorManager.error,
                    borderRadius: BorderRadius.circular(AppRadius.r4),
                  ),
                  child: Text(
                    offer.isActive ? 'Active' : 'Inactive',
                    style: getRegularStyle(
                      fontSize: AppFontSize.s10,
                      color: ColorManager.surface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
