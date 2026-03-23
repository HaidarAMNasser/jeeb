import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:shimmer/shimmer.dart';

class _ProductShimmerColors {
  static Color get base => ColorManager.defaultWhite.withValues(alpha: 0.12);
  static Color get highlight =>
      ColorManager.defaultWhite.withValues(alpha: 0.25);
}

/// Skeleton matching [ProductListItem] (carousel height + white info block).
class ProductListItemShimmer extends StatelessWidget {
  const ProductListItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Shimmer.fromColors(
          baseColor: _ProductShimmerColors.base,
          highlightColor: _ProductShimmerColors.highlight,
          child: Padding(
            padding: EdgeInsets.only(bottom: AppPadding.p12.h),
            child: Container(
              height: 140.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.r12)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-screen initial loading for the products list ("show all products").
class ProductListPageShimmer extends StatelessWidget {
  const ProductListPageShimmer({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(AppPadding.p16),
      itemCount: itemCount,
      itemBuilder: (_, __) => const ProductListItemShimmer(),
    );
  }
}

/// Bottom of list while the next page is loading.
class ProductListPaginationShimmer extends StatelessWidget {
  const ProductListPaginationShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppPadding.p16),
      child: const ProductListItemShimmer(),
    );
  }
}

/// Compact shimmer for embedded lists (e.g. client home).
class ProductsShimmer extends StatelessWidget {
  const ProductsShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      separatorBuilder: (_, __) => SizedBox(height: AppHeight.s12),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: ColorManager.defaultWhite.withOpacity(0.12),
          highlightColor: ColorManager.defaultWhite.withOpacity(0.25),
          child: Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
          ),
        );
      },
    );
  }
}
