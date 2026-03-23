import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:shimmer/shimmer.dart';

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
              baseColor: ColorManager.defaultWhite.withOpacity(0.12),
              highlightColor: ColorManager.defaultWhite.withOpacity(0.25),
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
              baseColor: ColorManager.defaultWhite.withOpacity(0.12),
              highlightColor: ColorManager.defaultWhite.withOpacity(0.25),
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
        SizedBox(
          height: 170.0.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            separatorBuilder: (_, __) => SizedBox(width: AppPadding.p12),
            itemBuilder: (context, index) {
              return Shimmer.fromColors(
                baseColor: ColorManager.defaultWhite.withOpacity(0.12),
                highlightColor: ColorManager.defaultWhite.withOpacity(0.25),
                child: Container(
                  width: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.r16),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
