import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/horizontal_scrollable_text.dart';
import 'package:jeeb_app/core/presentation/widgets/merchant_default_cover_image.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';
import 'package:jeeb_app/core/presentation/routes/routes.dart';
import 'package:jeeb_app/core/presentation/routes/route_manager.dart';
import 'package:jeeb_app/features/merchant/merchant_details/domain/entities/merchant_entity.dart';

class MerchantCard extends StatelessWidget {
  final MerchantEntity merchant;

  const MerchantCard({super.key, required this.merchant});

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
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: Container(
        height: 200.0.h,
        decoration: BoxDecoration(
          color: ColorManager.surface,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(AppRadius.r16),
                      ),
                      child:
                          merchant.image != null && merchant.image!.isNotEmpty
                          ? Image.network(
                              merchant.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const MerchantDefaultCoverImage(
                                    fillParent: true,
                                  ),
                            )
                          : const MerchantDefaultCoverImage(fillParent: true),
                    ),
                  ),
                  if (merchant.isOnline == true)
                    Positioned(
                      top: AppPadding.p8,
                      right: AppPadding.p8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: ColorManager.defaultWhite,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Material(
                color: ColorManager.lightPrimary,
                elevation: 2,
                shadowColor: ColorManager.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(AppRadius.r16),
                  bottomRight: Radius.circular(AppRadius.r16),
                ),
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: AppPadding.p8,
                    end: AppPadding.p12,
                    top: AppPadding.p12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
              
                    children: [
                      Expanded(
                        child: HorizontalScrollableText(
                          text: merchant.restaurantName,
                          textStyle: getSemiBoldStyle(
                            fontSize: AppFontSize.s16,
                            color: ColorManager.productNameColor,
                          ),
                          height: AppHeight.s26,
                        ),
                      ),
                      if (merchant.cityName != null &&
                          merchant.cityName!.isNotEmpty) ...[
                        SizedBox(width: AppPadding.p8),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: AppPadding.p6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: ColorManager.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppRadius.r8),
                          ),
                          child: CustomText(
                            text: merchant.cityName!,
                            textStyle: getRegularStyle(
                              fontSize: AppFontSize.s14,
                              color: ColorManager.primary,
                            ),
                            maxLines: 1,
                            textOverflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
