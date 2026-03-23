import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/custom_cached_network_image.dart';
import 'package:jeeb_app/core/presentation/widgets/merchant_default_cover_image.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';

/// Merchant row in the list: wide horizontal image (like product cards), then
/// restaurant name + address. Email is shown on merchant details only.
class MerchantListItem extends StatelessWidget {
  const MerchantListItem({super.key, required this.merchant});

  final MerchantEntity merchant;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AppRouter.navigateTo(
          context,
          Routes.merchantDetails,
          arguments: {'merchantId': merchant.id},
        );
      },
      child: Material(
        color: Colors.transparent,
        elevation: 2,
        shadowColor: ColorManager.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.r16),
        child: Container(
          margin: EdgeInsets.only(bottom: AppMargin.m16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(
              color: ColorManager.primary.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _MerchantListItemHeaderImage(imageUrl: merchant.image),
              Container(
                width: double.infinity,
                color: ColorManager.lightPrimary,
                child: Padding(
                  padding: EdgeInsets.all(AppPadding.p16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        text: merchant.restaurantName,
                        textStyle: getBoldStyle(
                          fontSize: AppFontSize.s18,
                          color: ColorManager.productNameColor,
                        ),
                        maxLines: 2,
                        textOverflow: TextOverflow.ellipsis,
                      ),
                      if (_formatAddress(merchant) != null) ...[
                        SizedBox(height: AppHeight.s8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 2.h),
                              child: Icon(
                                Icons.location_on_outlined,
                                size: AppSize.s18,
                                color: ColorManager.primary.withValues(
                                  alpha: 0.75,
                                ),
                              ),
                            ),
                            SizedBox(width: AppWidth.s8),
                            Expanded(
                              child: CustomText(
                                text: _formatAddress(merchant)!,
                                textStyle: getRegularStyle(
                                  fontSize: AppFontSize.s12,
                                  color: ColorManager.primary,
                                ),
                                maxLines: 3,
                                textOverflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Prefer street/area [location], else city + country.
  static String? _formatAddress(MerchantEntity m) {
    final loc = m.location?.trim();
    if (loc != null && loc.isNotEmpty) return loc;
    final city = m.cityName;
    final country = m.countryName;
    if (city != null && country != null) return '$city, $country';
    return city ?? country;
  }
}

/// Full-width banner image (same idea as [ProductItemImageCarousel] height).
class _MerchantListItemHeaderImage extends StatelessWidget {
  const _MerchantListItemHeaderImage({this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(AppRadius.r16),
        topRight: Radius.circular(AppRadius.r16),
      ),
      child: SizedBox(
        height: 150.h,
        width: double.infinity,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? CustomCachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 150.h,
                errorWidget: MerchantDefaultCoverImage(height: 150.h),
              )
            : MerchantDefaultCoverImage(height: 150.h),
      ),
    );
  }
}
