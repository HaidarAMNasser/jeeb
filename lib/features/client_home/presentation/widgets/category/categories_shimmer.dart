import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:shimmer/shimmer.dart';

class CategoriesShimmer extends StatelessWidget {
  const CategoriesShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: AppHeight.s100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 6,
        separatorBuilder: (_, __) => SizedBox(width: AppPadding.p12),
        itemBuilder: (context, index) {
          return Column(
            children: [
              Shimmer.fromColors(
                baseColor: ColorManager.defaultWhite.withOpacity(0.12),
                highlightColor: ColorManager.defaultWhite.withOpacity(0.25),
                child: Container(
                  width: AppHeight.s66,
                  height: AppHeight.s66,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: AppHeight.s5),
              Shimmer.fromColors(
                baseColor: ColorManager.defaultWhite.withOpacity(0.12),
                highlightColor: ColorManager.defaultWhite.withOpacity(0.25),
                child: Container(
                  width: AppWidth.s50,
                  height: AppHeight.s12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSize.s3),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
