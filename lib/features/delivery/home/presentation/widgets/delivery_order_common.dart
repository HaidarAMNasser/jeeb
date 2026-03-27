import 'package:flutter/material.dart';
import 'package:jeeb_app/core/presentation/theme/colors_manager.dart';
import 'package:jeeb_app/core/presentation/theme/font_manager.dart';
import 'package:jeeb_app/core/presentation/theme/styles_manager.dart';
import 'package:jeeb_app/core/presentation/theme/values_manager.dart';
import 'package:jeeb_app/core/presentation/widgets/text_widget.dart';

Widget buildAvatarIcon(IconData icon, Color color) {
  return Container(
    padding: EdgeInsets.all(AppPadding.p8),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: AppSize.s20, color: color),
  );
}

Widget buildPriceTag(int price) {
  return Container(
    padding: EdgeInsets.symmetric(
      horizontal: AppPadding.p12,
      vertical: AppPadding.p6,
    ),
    decoration: BoxDecoration(
      color: ColorManager.primary,
      borderRadius: BorderRadius.circular(AppSize.s12),
      boxShadow: [
        BoxShadow(
          color: ColorManager.primary.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: CustomText(
      text: '\$${(price / 100).toStringAsFixed(2)}',
      textStyle: getBoldStyle(fontSize: AppFontSize.s14, color: Colors.white),
    ),
  );
}
