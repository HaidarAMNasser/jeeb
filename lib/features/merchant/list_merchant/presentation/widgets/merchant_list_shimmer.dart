import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:shimmer/shimmer.dart';

/// Shimmer colors matching other list shimmers in the app.
class _MerchantShimmerColors {
  static Color get base => ColorManager.defaultWhite.withValues(alpha: 0.12);
  static Color get highlight =>
      ColorManager.defaultWhite.withValues(alpha: 0.25);
}

/// Skeleton matching [MerchantListItem] (wide image + title/address block).
class MerchantListItemShimmer extends StatelessWidget {
  const MerchantListItemShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Shimmer.fromColors(
          baseColor: _MerchantShimmerColors.base,
          highlightColor: _MerchantShimmerColors.highlight,
          child: Padding(
            padding: EdgeInsets.only(bottom: AppPadding.p16),
            child: Container(
              height: 150.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(AppRadius.r16)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Full-screen initial loading for the merchants list.
class MerchantListPageShimmer extends StatelessWidget {
  const MerchantListPageShimmer({super.key, this.itemCount = 4});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: AppPadding.p16),
      itemCount: itemCount,
      itemBuilder: (_, __) => const MerchantListItemShimmer(),
    );
  }
}

/// Shown at the bottom of the list while the next page is loading.
class MerchantListPaginationShimmer extends StatelessWidget {
  const MerchantListPaginationShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppPadding.p16),
      child: const MerchantListItemShimmer(),
    );
  }
}
