import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:shimmer/shimmer.dart';

class _MerchantShimmerColors {
  static Color get base => ColorManager.defaultWhite.withOpacity(0.12);
  static Color get highlight => ColorManager.defaultWhite.withOpacity(0.25);
}

/// Skeleton matching [MerchantCard] (image area + footer strip).
class MerchantCardShimmer extends StatelessWidget {
  const MerchantCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _MerchantShimmerColors.base,
      highlightColor: _MerchantShimmerColors.highlight,
      child: Container(
        height: 200.0.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(AppRadius.r16),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsetsDirectional.only(
                  start: AppPadding.p8,
                  end: AppPadding.p12,
                  top: AppPadding.p12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppRadius.r16),
                    bottomRight: Radius.circular(AppRadius.r16),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: AppHeight.s16,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.r8),
                        ),
                      ),
                    ),
                    SizedBox(width: AppPadding.p8),
                    Container(
                      width: 56,
                      height: AppHeight.s16,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.r8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading state for [ClientHomeMerchantsSection] vertical list.
class MerchantsShimmer extends StatelessWidget {
  const MerchantsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Shimmer.fromColors(
              baseColor: _MerchantShimmerColors.base,
              highlightColor: _MerchantShimmerColors.highlight,
              child: Container(
                width: 100,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSize.s3),
                ),
              ),
            ),
            Shimmer.fromColors(
              baseColor: _MerchantShimmerColors.base,
              highlightColor: _MerchantShimmerColors.highlight,
              child: Container(
                width: 60,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSize.s3),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppHeight.s12),
        for (int i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.only(bottom: AppSize.s20.h),
            child: const MerchantCardShimmer(),
          ),
      ],
    );
  }
}
