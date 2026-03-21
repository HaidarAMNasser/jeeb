import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:shimmer/shimmer.dart';

class OffersShimmer extends StatelessWidget {
  const OffersShimmer({super.key});

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
        SizedBox(height: AppHeight.s16),
        SizedBox(
          height: 200,
          child: Shimmer.fromColors(
            baseColor: ColorManager.defaultWhite.withOpacity(0.12),
            highlightColor: ColorManager.defaultWhite.withOpacity(0.25),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.r16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
