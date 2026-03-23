import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

class ProductItemBadges extends StatelessWidget {
  final String? categoryName;
  final double? rating;

  const ProductItemBadges({
    super.key,
    this.categoryName,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: AppPadding.p12,
            vertical: AppPadding.p4,
          ),
          decoration: BoxDecoration(
            color: ColorManager.lightPrimary,
            borderRadius: BorderRadius.circular(AppRadius.r20),
          ),
          child: CustomText(
            text: categoryName ?? '',
            textStyle: getSemiBoldStyle(
              fontSize: AppFontSize.s12,
              color: ColorManager.primary,
            ),
          ),
        ),
        if (rating != null)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: AppPadding.p8,
              vertical: AppPadding.p4,
            ),
            decoration: BoxDecoration(
              color: ColorManager.ratingBackgroundColor,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star,
                  color: ColorManager.primary,
                  size: AppSize.s16,
                ),
                SizedBox(width: AppWidth.s4),
                CustomText(
                  text: rating!.toStringAsFixed(1),
                  textStyle: getSemiBoldStyle(
                    fontSize: AppFontSize.s12,
                    color: ColorManager.primary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
